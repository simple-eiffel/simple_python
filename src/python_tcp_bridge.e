note
	description: "[
		A PYTHON_BRIDGE that talks to a Python server over one TCP connection
		using length-prefixed JSON frames: the shared transport of
		IPC_PYTHON_BRIDGE (python_ipc_server.py) and GRPC_PYTHON_BRIDGE
		(python_grpc_server.py).

		Wire format, both directions (read from the two Python servers):
		  4-byte big-endian unsigned payload length, then that many bytes of
		  UTF-8 JSON. The request is PYTHON_MESSAGE.to_json; the reply is
		  {"type": "VALIDATION_RESPONSE" | "ERROR", "message_id": <echoed id>,
		   "attributes": {...}}. One reply per request, in order, on a
		  connection the server keeps open until the client closes it.

		Lifecycle: `initialize' connects (simple_net CLIENT_SOCKET);
		`send_message' sends one frame, waits for the reply frame, checks
		that it answers this request (same message_id) and caches it for
		`receive_message'. Any failure closes the connection, so
		`is_connected' is False whenever `has_error' holds; the next
		`send_message' reconnects. `close' ends the connection.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

deferred class
	PYTHON_TCP_BRIDGE

inherit
	PYTHON_BRIDGE

feature {NONE} -- Initialization

	make_tcp (a_host: READABLE_STRING_GENERAL; a_port: INTEGER; a_timeout_ms: INTEGER)
			-- Bridge for the server at `a_host':`a_port', waiting up to `a_timeout_ms' per I/O.
		require
			host_not_empty: not a_host.is_empty
			port_valid: a_port > 0 and a_port < 65536
			timeout_positive: a_timeout_ms > 0
		do
			create host.make_from_string_general (a_host)
			port := a_port
			timeout_ms := a_timeout_ms
			create last_error_message.make_empty
			create pending_messages.make (10)
		ensure
			host_set: host.same_string_general (a_host)
			port_set: port = a_port
			timeout_set: timeout_ms = a_timeout_ms
			not_initialized: not is_initialized
			not_connected: not is_connected
			no_error: not has_error
		end

feature -- Access

	host: STRING_32
			-- Server host (IPv4 literal or name).

	port: INTEGER
			-- Server port.

	timeout_ms: INTEGER
			-- Limit, in milliseconds, on each connect, send and receive wait.

	active_connections: INTEGER
			-- Number of open connections to the server (0 or 1).
		do
			if is_connected then
				Result := 1
			end
		ensure
			non_negative: Result >= 0
			at_most_one: Result <= 1
		end

	transport_name: STRING
			-- Name used in error messages and logs ("IPC", "gRPC").
		deferred
		end

feature -- Status (From PYTHON_BRIDGE)

	is_initialized: BOOLEAN
			-- Has `initialize' succeeded?

	is_connected: BOOLEAN
			-- Is a TCP connection to the server open?

	has_error: BOOLEAN
			-- Did the last operation fail?

	last_error_message: STRING_32
			-- Why the last operation failed; empty after a success.

feature -- Bridge Lifecycle (From PYTHON_BRIDGE)

	initialize: BOOLEAN
			-- Connect to `host':`port'. Returns true if connected.
		do
			Result := open_connection
			is_initialized := Result
		ensure then
			initialized_on_success: Result implies (is_initialized and is_connected)
			not_initialized_on_failure: (not Result) implies (not is_initialized)
			error_set_on_failure: (not Result) implies has_error
			no_resources_on_failure: (not Result) implies (not is_connected)
		end

	close
			-- Close the connection, if open. Safe to call more than once.
		do
			if attached socket as al_socket then
				al_socket.close
			end
			socket := Void
			is_connected := False
		ensure then
			not_connected: not is_connected
			no_socket: socket = Void
		end

feature -- Message Operations (From PYTHON_BRIDGE)

	send_message (a_message: PYTHON_MESSAGE): BOOLEAN
			-- Send `a_message' as one frame and wait for the server's reply frame.
			-- True when a reply to this message (same message_id) arrived and parsed;
			-- `receive_message' then returns it. Reconnects first if not connected.
		local
			l_frame, l_header, l_body: ARRAY [NATURAL_8]
			l_length: INTEGER
			l_json: STRING_8
		do
			if not a_message.is_frozen then
				a_message.freeze
			end
			cached_response := Void
			if is_connected or else open_connection then
				if attached socket as al_socket then
					l_json := a_message.to_json.as_json
					l_frame := encode_frame (utf_8_bytes (l_json))
					logger.log_info (transport_name + " request frame: 4 + " + l_json.count.out + " bytes: " + l_json)
					if not al_socket.send (l_frame) then
						fail_on_socket ("send request", al_socket)
					else
						bytes_sent := bytes_sent + l_frame.count
						messages_sent := messages_sent + 1
						l_header := al_socket.receive_exactly (4)
						if l_header.count < 4 then
							fail_on_socket ("receive reply length", al_socket)
						else
							l_length := frame_length (l_header)
							if l_length < 0 or l_length > Max_frame_bytes then
								fail ({STRING_32} "reply frame length " + l_length.out + {STRING_32} " is out of range")
							else
								l_body := al_socket.receive_exactly (l_length)
								if l_body.count < l_length then
									fail_on_socket ("receive reply body", al_socket)
								else
									bytes_received := bytes_received + 4 + l_length
									Result := accept_reply (l_body, a_message.message_id)
								end
							end
						end
					end
				end
			end
		ensure then
			success_clears_error: Result implies not has_error
			success_caches_reply: Result implies attached cached_response as al_r
				and then al_r.message_id.same_string (a_message.message_id)
			failure_implies_error: (not Result) implies has_error
			failure_disconnects: (not Result) implies not is_connected
			bytes_non_decreasing: bytes_sent >= old bytes_sent
		end

	receive_message: detachable PYTHON_MESSAGE
			-- Reply to the last successful `send_message' (Void if it failed).
		do
			Result := cached_response
		end

feature -- Configuration (From PYTHON_BRIDGE)

	set_timeout (a_timeout_ms: INTEGER)
			-- Set the I/O timeout in milliseconds (applies to an open connection too).
		do
			timeout_ms := a_timeout_ms
			if attached socket as al_socket then
				al_socket.set_timeout (timeout_seconds)
			end
		ensure then
			timeout_set: timeout_ms = a_timeout_ms
		end

feature -- Message Framing

	message_frame_format: STRING = "4-byte big-endian length + UTF-8 JSON payload"
			-- Frame layout on the wire.

	Max_frame_bytes: INTEGER = 16_777_216
			-- Largest reply payload accepted (16 MiB).

	encode_frame (a_payload: ARRAY [NATURAL_8]): ARRAY [NATURAL_8]
			-- `a_payload' with its 4-byte big-endian length in front.
		require
			payload_not_void: a_payload /= Void
		local
			l_length: INTEGER
			l_i: INTEGER
		do
			l_length := a_payload.count
			create Result.make_filled (0, 1, 4 + l_length)
			Result [1] := ((l_length |>> 24) & 0xFF).to_natural_8
			Result [2] := ((l_length |>> 16) & 0xFF).to_natural_8
			Result [3] := ((l_length |>> 8) & 0xFF).to_natural_8
			Result [4] := (l_length & 0xFF).to_natural_8
			from
				l_i := 1
			until
				l_i > l_length
			loop
				Result [4 + l_i] := a_payload [a_payload.lower + l_i - 1]
				l_i := l_i + 1
			variant
				l_length - l_i + 1
			end
		ensure
			result_not_void: Result /= Void
			result_size_correct: Result.count = 4 + a_payload.count
		end

	decode_frame (a_frame: ARRAY [NATURAL_8]): detachable ARRAY [NATURAL_8]
			-- Payload of `a_frame', or Void when its length prefix claims more
			-- bytes than follow (or is negative).
		require
			frame_not_void: a_frame /= Void
			frame_large_enough: a_frame.count >= 4
		local
			l_payload_length: INTEGER
			l_i: INTEGER
		do
			l_payload_length := frame_length (a_frame)
			if l_payload_length >= 0 and l_payload_length <= a_frame.count - 4 then
				create Result.make_filled (0, 1, l_payload_length)
				from
					l_i := 1
				until
					l_i > l_payload_length
				loop
					Result [l_i] := a_frame [a_frame.lower + 3 + l_i]
					l_i := l_i + 1
				variant
					l_payload_length - l_i + 1
				end
			end
		ensure
			payload_matches_prefix: attached Result as al_r implies al_r.count = frame_length (a_frame)
		end

	frame_length (a_frame: ARRAY [NATURAL_8]): INTEGER
			-- Length prefix in the first 4 bytes of `a_frame' (negative if the top bit is set).
		require
			frame_large_enough: a_frame.count >= 4
		local
			l_base: INTEGER
		do
			l_base := a_frame.lower
			Result := (a_frame [l_base].to_integer_32 |<< 24) | (a_frame [l_base + 1].to_integer_32 |<< 16)
				| (a_frame [l_base + 2].to_integer_32 |<< 8) | a_frame [l_base + 3].to_integer_32
		end

feature {NONE} -- Implementation

	socket: detachable CLIENT_SOCKET
			-- Open connection, if any.

	pending_messages: ARRAYED_LIST [PYTHON_MESSAGE]
			-- Queue of messages received but not yet consumed.

	cached_response: detachable PYTHON_MESSAGE
			-- Reply to the last successful `send_message'.

	bytes_sent: INTEGER_64
			-- Total bytes sent, length prefixes included.

	bytes_received: INTEGER_64
			-- Total bytes received, length prefixes included.

	messages_sent: INTEGER
			-- Count of request frames sent.

	messages_received: INTEGER
			-- Count of replies accepted.

	timeout_seconds: REAL
			-- `timeout_ms' in seconds.
		do
			Result := (timeout_ms / 1000.0).truncated_to_real
		end

	logger: SIMPLE_LOGGER
			-- Shared log.
		once
			create Result.make_to_file ("logs/simple_python.log")
		end

	open_connection: BOOLEAN
			-- Connect to `host':`port'; on failure set the error state.
		local
			l_socket: CLIENT_SOCKET
		do
			close
			create l_socket.make_for_host_port (host.to_string_8, port)
			l_socket.set_timeout (timeout_seconds)
			if l_socket.connect then
				socket := l_socket
				is_connected := True
				has_error := False
				last_error_message.wipe_out
				Result := True
				logger.log_info (transport_name + " connected to " + l_socket.remote_address.as_string)
			else
				fail ({STRING_32} "cannot connect: " + l_socket.last_error_string)
			end
		ensure
			success_connected: Result implies (is_connected and not has_error)
			failure_error: (not Result) implies (has_error and not is_connected)
		end

	accept_reply (a_body: ARRAY [NATURAL_8]; a_request_id: STRING_32): BOOLEAN
			-- Parse reply payload `a_body'; True if it answers request `a_request_id'.
		local
			l_text: STRING_32
		do
			l_text := (create {UTF_CONVERTER}).utf_8_string_8_to_string_32 (string_of_bytes (a_body))
			logger.log_info ({STRING_32} "reply frame: 4 + " + a_body.count.out + {STRING_32} " bytes: " + l_text)
			if not extract_response_from_body (l_text) then
				fail ({STRING_32} "unparseable reply: " + l_text.substring (1, l_text.count.min (200)))
			elseif attached cached_response as al_reply and then al_reply.message_id.same_string (a_request_id) then
				messages_received := messages_received + 1
				has_error := False
				last_error_message.wipe_out
				Result := True
			else
				cached_response := Void
				fail ({STRING_32} "reply does not answer request " + a_request_id)
			end
		ensure
			success_cached: Result implies attached cached_response
			failure_error: (not Result) implies has_error
		end

	fail_on_socket (a_step: STRING; a_socket: CLIENT_SOCKET)
			-- Fail because `a_step' did not complete on `a_socket'.
		local
			l_why: STRING_32
		do
			create l_why.make_from_string_general (a_step)
			if a_socket.last_error_code /= 0 then
				l_why.append ({STRING_32} ": ")
				l_why.append_string_general (a_socket.last_error_string)
			elseif a_socket.is_at_end_of_stream then
				l_why.append ({STRING_32} ": server closed the connection")
			end
			fail (l_why)
		ensure
			error: has_error and not is_connected
		end

	fail (a_why: READABLE_STRING_GENERAL)
			-- Record failure `a_why' (prefixed with the transport and endpoint) and drop the connection.
		require
			reason_not_empty: not a_why.is_empty
		do
			close
			has_error := True
			create last_error_message.make_from_string_general (transport_name)
			last_error_message.append ({STRING_32} " ")
			last_error_message.append (host)
			last_error_message.append ({STRING_32} ":")
			last_error_message.append_string_general (port.out)
			last_error_message.append ({STRING_32} " ")
			last_error_message.append_string_general (a_why)
			logger.log_error (last_error_message)
		ensure
			error: has_error and not is_connected
			message_set: not last_error_message.is_empty
		end

	utf_8_bytes (a_utf_8: STRING_8): ARRAY [NATURAL_8]
			-- The bytes of `a_utf_8' (already UTF-8 encoded), unchanged.
		local
			i: INTEGER
		do
			create Result.make_filled (0, 1, a_utf_8.count)
			from
				i := 1
			until
				i > a_utf_8.count
			loop
				Result [i] := a_utf_8.code (i).to_natural_8
				i := i + 1
			variant
				a_utf_8.count - i + 1
			end
		ensure
			same_count: Result.count = a_utf_8.count
		end

	string_of_bytes (a_bytes: ARRAY [NATURAL_8]): STRING_8
			-- `a_bytes' as 8-bit characters, unchanged.
		do
			create Result.make (a_bytes.count)
			across a_bytes as ic loop
				Result.append_character (ic.to_character_8)
			end
		ensure
			same_count: Result.count = a_bytes.count
		end

	extract_response_from_body (a_body: STRING_32): BOOLEAN
			-- Parse reply JSON `a_body' into `cached_response'.
			-- True for a VALIDATION_RESPONSE or ERROR object carrying a message_id.
		local
			l_parser: SIMPLE_JSON
			l_type_lower: STRING_32
			l_obj: SIMPLE_JSON_OBJECT
		do
			create l_parser
			if attached l_parser.parse (a_body) as l_parsed and then l_parsed.is_object then
				l_obj := l_parsed.as_object
				if attached l_obj.item ("type") as l_type_val and then l_type_val.is_string
					and then attached l_obj.item ("message_id") as l_id_val and then l_id_val.is_string
					and then not l_id_val.as_string_32.is_empty
				then
					l_type_lower := l_type_val.as_string_32.as_lower
					if l_type_lower ~ {STRING_32} "validation_response" then
						create_validation_response (l_id_val.as_string_32, l_obj)
						Result := True
					elseif l_type_lower ~ {STRING_32} "error" then
						create_error_message (l_id_val.as_string_32, l_obj)
						Result := True
					end
				end
			end
		ensure
			parsed_means_cached: Result implies attached cached_response
		end

	create_validation_response (a_message_id: STRING_32; a_json: SIMPLE_JSON_OBJECT)
			-- Cache a PYTHON_VALIDATION_RESPONSE built from `a_json'.
		require
			id_not_empty: not a_message_id.is_empty
		local
			l_response: PYTHON_VALIDATION_RESPONSE
		do
			create l_response.make (a_message_id)
			if attached a_json.item ("attributes") as l_attrs_val and then l_attrs_val.is_object then
				across l_attrs_val.as_object.keys as ic loop
					if attached l_attrs_val.as_object.item (ic) as l_value then
						l_response.set_attribute (ic, l_value)
					end
				end
			end
			l_response.freeze
			cached_response := l_response
		ensure
			cached: attached cached_response
		end

	create_error_message (a_message_id: STRING_32; a_json: SIMPLE_JSON_OBJECT)
			-- Cache a PYTHON_ERROR built from `a_json'.
		require
			id_not_empty: not a_message_id.is_empty
		local
			l_error: PYTHON_ERROR
		do
			create l_error.make (a_message_id)
			if attached a_json.item ("attributes") as l_attrs_val and then l_attrs_val.is_object then
				across l_attrs_val.as_object.keys as ic loop
					if attached l_attrs_val.as_object.item (ic) as l_value then
						l_error.set_attribute (ic, l_value)
					end
				end
			end
			l_error.freeze
			cached_response := l_error
		ensure
			cached: attached cached_response
		end

invariant
	host_not_empty: not host.is_empty
	port_in_range: port > 0 and port < 65536
	timeout_positive: timeout_ms > 0
	error_consistency: has_error = (last_error_message.count > 0)
	connected_has_socket: is_connected implies attached socket
	pending_messages_not_void: pending_messages /= Void

end
