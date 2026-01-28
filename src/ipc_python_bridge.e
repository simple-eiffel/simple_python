note
	description: "[
		Windows named pipes IPC bridge for ultra-low-latency Eiffel-Python communication.

		Uses 4-byte length prefix + binary/JSON payload for message framing.
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
			-- Create IPC bridge using Windows named pipe.
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
			-- TODO: Phase 4 Implementation
			Result := 0
		ensure
			non_negative: Result >= 0
			bounded: Result <= 10000  -- Reasonable upper bound
		end

feature -- Status (From PYTHON_BRIDGE)

	is_initialized: BOOLEAN
			-- Is named pipe created and open?

	is_connected: BOOLEAN
			-- Is pipe currently connected to client?

	has_error: BOOLEAN
			-- Did last operation fail?

	last_error_message: STRING_32
			-- Human-readable error from last operation.

feature -- Bridge Lifecycle (From PYTHON_BRIDGE)

	initialize: BOOLEAN
			-- Create and open Windows named pipe for listening.
			-- Returns true if pipe created successfully.
		do
			-- For Phase 4: Basic stub implementation
			-- Full implementation requires Win32 API integration via inline C for CreateNamedPipe
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
			-- Close named pipe and disconnect from client.
		do
			-- TODO: Phase 4 Implementation
			-- 1. Close pipe connection if active
			-- 2. Set is_connected := False
			is_connected := False
		ensure then
			not_connected: not is_connected
		end

feature -- Message Operations (From PYTHON_BRIDGE)

	send_message (a_message: PYTHON_MESSAGE): BOOLEAN
			-- Send message via IPC named pipe with 4-byte length prefix.
		local
			l_binary: ARRAY [NATURAL_8]
		do
			-- Serialize message to binary
			a_message.freeze
			l_binary := a_message.to_binary

			-- Note: to_binary already includes 4-byte length prefix, so use it directly
			-- Track bytes sent
			bytes_sent := bytes_sent + l_binary.count.to_integer_64
			messages_sent := messages_sent + 1

			-- For Phase 4: Basic stub - would write to named pipe
			-- Full implementation requires Win32 API integration via inline C
			Result := True
		ensure then
			success_implies_bytes_sent: Result implies (bytes_sent >= old bytes_sent)
			failure_implies_error: (not Result) implies has_error
			error_message_consistent: has_error implies (last_error_message.count > 0)
		end

	receive_message: detachable PYTHON_MESSAGE
			-- Receive next message from IPC pipe (with length prefix).
			-- Blocks until message received or timeout occurs.
		do
			-- For Phase 4: Basic stub implementation
			-- Full implementation requires Win32 API integration via inline C:
			-- 1. Read 4-byte length prefix from pipe
			-- 2. Read payload of specified length
			-- 3. Decode binary/JSON to PYTHON_MESSAGE
			-- 4. Track bytes_received
			-- 5. Return Void on timeout or error

			-- Stub: Return Void (timeout case) - would be populated in Phase 5
			Result := Void
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

	bytes_sent: INTEGER_64
			-- Total bytes sent via pipe (including length prefix).

	bytes_received: INTEGER_64
			-- Total bytes received via pipe (including length prefix).

	messages_sent: INTEGER
			-- Count of messages sent.

	messages_received: INTEGER
			-- Count of messages received.

invariant
	pipe_name_not_empty: pipe_name /= Void and then pipe_name.count > 0
	timeout_positive: timeout_ms > 0
	error_consistency: has_error = (last_error_message.count > 0)
	pending_messages_not_void: pending_messages /= Void

end
