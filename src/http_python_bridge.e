note
	description: "[
		HTTP REST bridge for Eiffel-Python communication via JSON over HTTP.

		Python clients POST validation requests to Eiffel server (running on specified host:port).
		Server responds with JSON validation results.

		Contract Specifications:
		- initialize: Starts HTTP server on configured host:port
		- send_message: Encodes message to JSON and sends HTTP response (or request from client)
		- receive_message: Receives HTTP POST request body and decodes from JSON
		- close: Stops HTTP server and releases resources

		Performance SLA:
		- Response time: ≤100ms (p95) for typical 10KB payload
		- Throughput: ≥1000 req/sec sustained
		- Error rate: <0.1% under load
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class
	HTTP_PYTHON_BRIDGE

inherit
	PYTHON_BRIDGE

create
	make_with_host_port

feature {NONE} -- Initialization

	make_with_host_port (a_host: STRING_32; a_port: INTEGER)
			-- Create HTTP bridge for given host and port.
		require
			host_not_empty: a_host /= Void and then a_host.count > 0
			port_valid: a_port > 0 and a_port < 65536
		do
			host := a_host
			port := a_port
			timeout_ms := 30000 -- 30 second default timeout
			is_initialized := False
			is_connected := False
			has_error := False
			create last_error_message.make_empty
			create pending_messages.make (10)
		ensure
			host_set: host.same_string (a_host)
			port_set: port = a_port
			not_initialized: not is_initialized
			not_connected: not is_connected
		end

feature -- Access

	host: STRING_32
			-- Host address to listen on (e.g., "0.0.0.0", "localhost").

	port: INTEGER
			-- Port number to listen on.

	timeout_ms: INTEGER
			-- Receive timeout in milliseconds.

	active_connections: INTEGER
			-- Number of currently active HTTP connections being handled.
		do
			-- TODO: Phase 4 Implementation
			Result := 0
		ensure
			non_negative: Result >= 0
			bounded: Result <= 10000  -- Reasonable upper bound
		end

feature {NONE} -- Logger

	logger: SIMPLE_LOGGER
			-- Shared logger for HTTP operations.
		once
			create Result.make_to_file ("logs/simple_python.log")
		end

feature -- Status (From PYTHON_BRIDGE)

	is_initialized: BOOLEAN
			-- Is HTTP server started?

	is_connected: BOOLEAN
			-- Is HTTP server running (listening for connections)?

	has_error: BOOLEAN
			-- Did last operation fail?

	last_error_message: STRING_32
			-- Human-readable error from last operation.

feature -- Bridge Lifecycle (From PYTHON_BRIDGE)

	initialize: BOOLEAN
			-- Start HTTP server on configured host:port.
			-- Returns true if server started successfully.
		do
			-- For Phase 4: Basic stub implementation
			-- Full implementation requires simple_http library integration
			-- Setting up HTTP server with route handlers for /validate POST endpoint
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
			-- Stop HTTP server and clean up resources.
		do
			-- TODO: Phase 4 Implementation
			-- 1. Stop HTTP server if running
			-- 2. Close all active connections
			-- 3. Release listening socket
			-- 4. Set is_connected := False
			is_connected := False
		ensure then
			not_connected: not is_connected
		end

feature -- Message Operations (From PYTHON_BRIDGE)

	send_message (a_message: PYTHON_MESSAGE): BOOLEAN
			-- Send message via HTTP POST to Python server and cache response.
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
			logger.log_info ("HTTP_BRIDGE.send_message START: message_id=" + a_message.message_id)

			-- Freeze message to make it SCOOP-safe
			a_message.freeze
			logger.verbose ("Message frozen for SCOOP")

			-- Get JSON representation
			l_json_obj := a_message.to_json
			l_json_string := l_json_obj.as_json
			logger.verbose ("JSON serialized, size=" + l_json_string.count.out)

			-- Track bytes sent
			bytes_sent := bytes_sent + l_json_string.count.to_integer_64
			messages_sent := messages_sent + 1

			-- Construct HTTP URL to Python server
			create l_url.make_from_string ("http://")
			l_url.append (host.to_string_8)
			l_url.append_string (":")
			l_url.append (port.out)
			l_url.append_string ("/validate")
			logger.verbose ("URL constructed: " + l_url)

			-- Create HTTP client and POST JSON data
			create l_http.make
			l_timeout_secs := timeout_ms // 1000  -- Convert milliseconds to seconds using integer division
			l_http.set_timeout (l_timeout_secs)
			logger.verbose ("HTTP client created, timeout=" + l_timeout_secs.out + " secs")

			-- POST JSON data to Python server
			logger.log_info ("HTTP POST to " + l_url)
			l_response := l_http.post (l_url, l_json_string)
			logger.log_info ("HTTP response status=" + l_response.status.out)

			-- Check for successful HTTP response
			if l_response.status = 200 and then attached l_response.body as l_body then
				logger.log_info ("HTTP 200 OK received, body_size=" + l_body.count.out)

				-- Convert response body from STRING_8 to STRING_32 for JSON parsing
				create l_response_body_32.make (l_body.count)
				across l_body as c loop
					l_response_body_32.append_character (c.item.to_character_32)
				end
				logger.verbose ("Response body: " + l_response_body_32.substring (1, (l_response_body_32.count.min (200))))

				-- Extract and parse response JSON
				logger.log_info ("Extracting response from body")
				if extract_response_from_body (l_response_body_32) then
					has_error := False
					create last_error_message.make_empty
					Result := True
					logger.log_info ("HTTP_BRIDGE.send_message SUCCESS: extracted response")
				else
					has_error := True
					create last_error_message.make_from_string ({STRING_32} "Failed to parse response from Python server")
					Result := False
					logger.log_error ("HTTP_BRIDGE.send_message FAILED: extract_response_from_body returned False")
				end
			else
				-- HTTP POST failed
				has_error := True
				logger.log_error ("HTTP response not 200 or no body")
				if l_response.status /= 200 then
					create l_error_msg.make_from_string ({STRING_32} "HTTP ")
					l_error_msg.append_string (l_response.status.out)
					l_error_msg.append ({STRING_32} " from ")
					l_error_msg.append_string (l_url)
					create last_error_message.make_from_string (l_error_msg)
					logger.log_error ("HTTP status error: " + l_error_msg)
				else
					create last_error_message.make_from_string ({STRING_32} "No response body from Python server")
					logger.log_error ("No response body from Python server")
				end
				Result := False
			end
		ensure then
			success_implies_bytes_sent: Result implies (bytes_sent > old bytes_sent)
			failure_implies_error: (not Result) implies has_error
			error_message_consistent: has_error implies (last_error_message.count > 0)
		end

	receive_message: detachable PYTHON_MESSAGE
			-- Return cached response message from last send_message().
			-- For HTTP, this is the Python server response to the last POST.
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

feature {NONE} -- Implementation Details

	pending_messages: ARRAYED_LIST [PYTHON_MESSAGE]
			-- Queue of messages received but not yet consumed by receive_message.

	cached_response: detachable PYTHON_MESSAGE
			-- Response message from last HTTP POST to Python server.

	bytes_sent: INTEGER_64
			-- Total bytes sent via HTTP responses.

	bytes_received: INTEGER_64
			-- Total bytes received via HTTP requests.

	messages_sent: INTEGER
			-- Count of messages sent.

	messages_received: INTEGER
			-- Count of messages received.

	extract_response_from_body (a_body: STRING_32): BOOLEAN
			-- Extract and parse response message from HTTP response body.
			-- Body is plain JSON payload (HTTP has no length prefix).
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
				logger.log_info ("Parsed JSON type - is_object: " + l_parsed.is_object.out + ", is_array: " + l_parsed.is_array.out + ", is_string: " + l_parsed.is_string.out + ", is_number: " + l_parsed.is_number.out + ", is_null: " + l_parsed.is_null.out)
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
					logger.log_error ("Parsed JSON is not an object: is_array=" + l_parsed.is_array.out + ", is_string=" + l_parsed.is_string.out + ", is_number=" + l_parsed.is_number.out + ", is_null=" + l_parsed.is_null.out)
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
	host_not_empty: host /= Void and then host.count > 0
	port_in_range: port > 0 and port < 65536
	timeout_positive: timeout_ms > 0
	error_consistency: has_error = (last_error_message.count > 0)
	pending_messages_not_void: pending_messages /= Void

end
