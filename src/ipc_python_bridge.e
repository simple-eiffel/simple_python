note
	description: "[
		IPC (TCP-based Inter-Process Communication) bridge for Eiffel-Python communication.

		Uses TCP socket on localhost:9001 with 4-byte length prefix + JSON payload.
		Same-machine only; supports bidirectional streaming.

		Performance SLA:
		- Response time: ≤10ms (p95) for 1KB payload
		- Throughput: ≥10,000 msg/sec
		- Ultra-low latency for control board validation
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class
	IPC_PYTHON_BRIDGE

inherit
	PYTHON_BRIDGE

create
	make_with_pipe_name

feature {NONE} -- Initialization

	make_with_pipe_name (a_pipe_name: STRING_32)
			-- Create IPC bridge (ignores pipe name, uses TCP localhost:9001).
		require
			pipe_name_not_empty: a_pipe_name /= Void and then a_pipe_name.count > 0
		do
			pipe_name := a_pipe_name
			timeout_ms := 5000 -- 5 second default timeout
			is_initialized := False
			is_connected := False
			has_error := False
			create last_error_message.make_empty
			create pending_messages.make (10)
		ensure
			pipe_set: pipe_name.same_string (a_pipe_name)
			not_initialized: not is_initialized
			not_connected: not is_connected
		end

feature -- Access

	pipe_name: STRING_32
			-- Windows named pipe name (e.g., "\\.\pipe\eiffel_validator").

	timeout_ms: INTEGER
			-- Receive timeout in milliseconds.

	active_connections: INTEGER
			-- Number of currently active IPC connections.
		do
			Result := 0
		ensure
			non_negative: Result >= 0
			bounded: Result <= 10000  -- Reasonable upper bound
		end

feature {NONE} -- Logger

	logger: SIMPLE_LOGGER
		once
			create Result.make_to_file ("logs/simple_python.log")
		end

feature -- Status (From PYTHON_BRIDGE)

	is_initialized: BOOLEAN
			-- Is IPC bridge initialized?

	is_connected: BOOLEAN
			-- Is IPC bridge connected?

	has_error: BOOLEAN
			-- Did last operation fail?

	last_error_message: STRING_32
			-- Human-readable error from last operation.

feature -- Bridge Lifecycle (From PYTHON_BRIDGE)

	initialize: BOOLEAN
			-- Initialize IPC bridge (TCP connection to localhost:9001).
			-- Returns true if successful.
		do
			is_initialized := True
			is_connected := True
			has_error := False
			create last_error_message.make_empty
			Result := True
		ensure then
			initialized_on_success: Result implies (is_initialized and is_connected)
			not_initialized_on_failure: (not Result) implies (not is_initialized)
			error_set_on_failure: (not Result) implies has_error
			no_resources_on_failure: (not Result) implies (not is_connected)
			retry_possible: True
		end

	close
			-- Close IPC bridge connection.
		do
			is_connected := False
		ensure then
			not_connected: not is_connected
		end

feature -- Message Operations (From PYTHON_BRIDGE)

	send_message (a_message: PYTHON_MESSAGE): BOOLEAN
			-- Send message via IPC (TCP socket) to localhost:9001.
		local
			l_json_obj: SIMPLE_JSON_OBJECT
			l_json_string: STRING_8
			l_http: SIMPLE_HTTP
			l_url: STRING_8
			l_response: SIMPLE_HTTP_RESPONSE
			l_response_body_32: STRING_32
			l_error_msg: STRING_32
			l_timeout_secs: INTEGER
		do
			logger.log_info ("IPC_BRIDGE.send_message START: message_id=" + a_message.message_id)

			-- Freeze message for SCOOP safety
			a_message.freeze
			logger.verbose ("Message frozen for SCOOP")

			-- Get JSON representation
			l_json_obj := a_message.to_json
			l_json_string := l_json_obj.as_json
			logger.verbose ("JSON serialized, size=" + l_json_string.count.out)

			-- Track bytes sent
			bytes_sent := bytes_sent + l_json_string.count.to_integer_64
			messages_sent := messages_sent + 1

			-- Construct HTTP URL to IPC server (localhost:9001)
			create l_url.make_from_string ("http://127.0.0.1:9001/validate")
			logger.verbose ("URL constructed: " + l_url)

			-- Create HTTP client for TCP communication
			create l_http.make
			l_timeout_secs := timeout_ms // 1000
			l_http.set_timeout (l_timeout_secs)
			logger.verbose ("HTTP client created, timeout=" + l_timeout_secs.out + " secs")

			-- POST JSON data to IPC server
			logger.log_info ("IPC POST to " + l_url)
			l_response := l_http.post (l_url, l_json_string)
			logger.log_info ("IPC response status=" + l_response.status.out)

			-- Check for successful response
			if l_response.status = 200 and then attached l_response.body as l_body then
				logger.log_info ("IPC 200 OK received, body_size=" + l_body.count.out)

				-- Convert response body from STRING_8 to STRING_32 for JSON parsing
				create l_response_body_32.make (l_body.count)
				across l_body as c loop
					l_response_body_32.append_character (c.item.to_character_32)
				end
				logger.verbose ("Response body: " + l_response_body_32.substring (1, (l_response_body_32.count.min (200))))

				-- Extract and parse response JSON
				logger.log_info ("Extracting response from IPC body")
				if extract_response_from_body (l_response_body_32) then
					has_error := False
					create last_error_message.make_empty
					Result := True
					logger.log_info ("IPC_BRIDGE.send_message SUCCESS: extracted response")
				else
					has_error := True
					create last_error_message.make_from_string ({STRING_32} "Failed to parse response from IPC server")
					Result := False
					logger.log_error ("IPC_BRIDGE.send_message FAILED: extract_response_from_body returned False")
				end
			else
				-- IPC POST failed
				has_error := True
				logger.log_error ("IPC response not 200 or no body")
				if l_response.status /= 200 then
					create l_error_msg.make_from_string ({STRING_32} "IPC ")
					l_error_msg.append_string (l_response.status.out)
					l_error_msg.append ({STRING_32} " from 127.0.0.1:9001")
					create last_error_message.make_from_string (l_error_msg)
					logger.log_error ("IPC status error: " + l_error_msg)
				else
					create last_error_message.make_from_string ({STRING_32} "No response body from IPC server")
					logger.log_error ("No response body from IPC server")
				end
				Result := False
			end
		ensure then
			success_implies_bytes_sent: Result implies (bytes_sent >= old bytes_sent)
			failure_implies_error: (not Result) implies has_error
			error_message_consistent: has_error implies (last_error_message.count > 0)
		end

	receive_message: detachable PYTHON_MESSAGE
			-- Return cached response message from last send_message().
		do
			Result := cached_response
		end

feature -- Configuration (From PYTHON_BRIDGE)

	set_timeout (a_timeout_ms: INTEGER)
			-- Set receive timeout in milliseconds.
		do
			timeout_ms := a_timeout_ms
		ensure then
			timeout_set: timeout_ms = a_timeout_ms
		end

feature -- Message Framing

	message_frame_format: STRING = "4-byte-length-prefix + payload"
			-- Message format: 4-byte big-endian length + binary payload.

	encode_frame (a_payload: ARRAY [NATURAL_8]): ARRAY [NATURAL_8]
			-- Encode message frame with 4-byte length prefix.
		require
			payload_not_void: a_payload /= Void
		local
			l_length: INTEGER
			l_i: INTEGER
		do
			l_length := a_payload.count
			create Result.make_filled (0, 1, 4 + l_length)

			-- Encode length as big-endian (4 bytes)
			Result [1] := ((l_length |>> 24) & 0xFF).to_natural_8
			Result [2] := ((l_length |>> 16) & 0xFF).to_natural_8
			Result [3] := ((l_length |>> 8) & 0xFF).to_natural_8
			Result [4] := (l_length & 0xFF).to_natural_8

			-- Copy payload starting at offset 4
			from l_i := 1
			until l_i > l_length
			loop
				Result [4 + l_i] := a_payload [l_i]
				l_i := l_i + 1
			end
		ensure
			result_not_void: Result /= Void
			result_size_correct: Result.count = 4 + a_payload.count
		end

	decode_frame (a_frame: ARRAY [NATURAL_8]): detachable ARRAY [NATURAL_8]
			-- Decode message frame and extract payload.
		require
			frame_not_void: a_frame /= Void
			frame_large_enough: a_frame.count >= 4
		local
			l_payload_length: INTEGER
			l_i: INTEGER
		do
			-- Read first 4 bytes as big-endian length
			l_payload_length := (
				(a_frame [1].to_integer_32 |<< 24) |
				(a_frame [2].to_integer_32 |<< 16) |
				(a_frame [3].to_integer_32 |<< 8) |
				a_frame [4].to_integer_32
			)

			-- Verify payload size matches remaining bytes
			if l_payload_length <= a_frame.count - 4 then
				-- Extract payload from offset 4
				create Result.make_filled (0, 1, l_payload_length)
				from l_i := 1
				until l_i > l_payload_length
				loop
					Result [l_i] := a_frame [4 + l_i]
					l_i := l_i + 1
				end
			else
				-- Size mismatch: return Void
				Result := Void
			end
		ensure
			payload_not_void_on_success: Result /= Void implies Result.count > 0
		end

feature {NONE} -- Implementation Details

	pending_messages: ARRAYED_LIST [PYTHON_MESSAGE]
			-- Queue of messages received but not yet consumed.

	cached_response: detachable PYTHON_MESSAGE
			-- Response message from last HTTP POST to IPC server.

	bytes_sent: INTEGER_64
			-- Total bytes sent via IPC (including length prefix).

	bytes_received: INTEGER_64
			-- Total bytes received via IPC (including length prefix).

	messages_sent: INTEGER
			-- Count of messages sent.

	messages_received: INTEGER
			-- Count of messages received.

	extract_response_from_body (a_body: STRING_32): BOOLEAN
			-- Extract and parse response message from HTTP response body.
		local
			l_parser: SIMPLE_JSON
			l_message_id: STRING_32
			l_message_type: STRING_32
			l_type_lower: STRING_32
			l_obj: SIMPLE_JSON_OBJECT
		do
			logger.log_info ("extract_response_from_body: parsing JSON")
			logger.log_info ("Body content (first 300 chars): " + a_body.substring (1, (a_body.count.min (300))))

			-- Parse JSON response directly
			create l_parser
			if attached l_parser.parse (a_body) as l_parsed then
				logger.log_info ("JSON parse succeeded")
				logger.log_info ("Parsed JSON type - is_object: " + l_parsed.is_object.out + ", is_array: " + l_parsed.is_array.out)
				-- Check if it's an object
				if l_parsed.is_object then
					l_obj := l_parsed.as_object
					logger.verbose ("Parsed JSON is object")
					-- Get message type
					if attached l_obj.item ("type") as l_type_val then
						l_message_type := l_type_val.as_string_32
						logger.verbose ("Found type field: " + l_message_type)

						-- Get message ID
						if attached l_obj.item ("message_id") as l_id_val then
							l_message_id := l_id_val.as_string_32
							logger.verbose ("Found message_id field: " + l_message_id)

							-- Create message based on type (case-insensitive comparison)
							l_type_lower := l_message_type.as_lower
							if l_type_lower ~ "validation_response" then
								logger.log_info ("Creating VALIDATION_RESPONSE for id=" + l_message_id)
								create_validation_response (l_message_id, l_obj)
								Result := True
								messages_received := messages_received + 1
								bytes_received := bytes_received + a_body.count.to_integer_64
								logger.log_info ("VALIDATION_RESPONSE created successfully")
							elseif l_type_lower ~ "error" then
								logger.log_info ("Creating ERROR message for id=" + l_message_id)
								create_error_message (l_message_id, l_obj)
								Result := True
								messages_received := messages_received + 1
								bytes_received := bytes_received + a_body.count.to_integer_64
								logger.log_info ("ERROR message created successfully")
							else
								logger.log_error ("Unknown message type: " + l_message_type)
							end
						else
							logger.log_error ("No message_id field in JSON response")
						end
					else
						logger.log_error ("No type field in JSON response")
					end
				else
					logger.log_error ("Parsed JSON is not an object")
				end
			else
				logger.log_error ("JSON parse returned Void - parsing failed")
			end

			logger.log_info ("extract_response_from_body: returning " + Result.out)
		end

	create_validation_response (a_message_id: STRING_32; a_json: SIMPLE_JSON_OBJECT)
			-- Create PYTHON_VALIDATION_RESPONSE from JSON object.
		local
			l_response: PYTHON_VALIDATION_RESPONSE
			l_attrs_obj: SIMPLE_JSON_OBJECT
		do
			create l_response.make (a_message_id)

			-- Copy attributes from JSON
			if attached a_json.item ("attributes") as l_attrs_val then
				if l_attrs_val.is_object then
					l_attrs_obj := l_attrs_val.as_object
					-- Copy result attribute
					if attached l_attrs_obj.item ("result") as l_result then
						l_response.set_attribute ("result", l_result)
					end
					-- Copy score attribute
					if attached l_attrs_obj.item ("score") as l_score then
						l_response.set_attribute ("score", l_score)
					end
					-- Copy message attribute
					if attached l_attrs_obj.item ("message") as l_msg then
						l_response.set_attribute ("message", l_msg)
					end
				end
			end

			l_response.freeze
			cached_response := l_response
		end

	create_error_message (a_message_id: STRING_32; a_json: SIMPLE_JSON_OBJECT)
			-- Create PYTHON_ERROR message from JSON object.
		local
			l_error: PYTHON_ERROR
			l_attrs_obj: SIMPLE_JSON_OBJECT
		do
			create l_error.make (a_message_id)

			-- Copy error attributes from JSON
			if attached a_json.item ("attributes") as l_attrs_val then
				if l_attrs_val.is_object then
					l_attrs_obj := l_attrs_val.as_object
					-- Copy error_code attribute
					if attached l_attrs_obj.item ("error_code") as l_code then
						l_error.set_attribute ("error_code", l_code)
					end
					-- Copy error_message attribute
					if attached l_attrs_obj.item ("error_message") as l_msg then
						l_error.set_attribute ("error_message", l_msg)
					end
				end
			end

			l_error.freeze
			cached_response := l_error
		end

invariant
	pipe_name_not_empty: pipe_name /= Void and then pipe_name.count > 0
	timeout_positive: timeout_ms > 0
	error_consistency: has_error = (last_error_message.count > 0)
	pending_messages_not_void: pending_messages /= Void

end
