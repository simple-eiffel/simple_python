note
	description: "[
		Real gRPC-bridge round trips against python_grpc_server.py (TCP
		127.0.0.1:9002, 4-byte big-endian length + JSON), started by
		start_grpc_server_blocking.py and stopped by its PID only.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

class TEST_GRPC_INTEGRATION_REAL

inherit
	PYTHON_BRIDGE_TEST_SUPPORT

feature -- Setup/Teardown

	setup
			-- Start this test's Python server through its launcher (start_grpc_server_blocking.py, port 9002).
		local
			l_server: PYTHON_TEST_SERVER
		do
			create l_server.make ("start_grpc_server_blocking.py", 9002)
			l_server.start
			server := l_server
			assert ({STRING_32} "grpc server started: " + l_server.last_launch_output, l_server.is_running)
		end

	teardown
			-- Stop the server `setup' started, and only that one.
		do
			if attached server as al_server then
				al_server.stop
			end
		end

feature {NONE} -- Process Management

	server: detachable PYTHON_TEST_SERVER
			-- Server started by `setup'.

feature -- Tests

	test_grpc_bridge_sends_to_python_server
			-- Requests on one connection each get their own VALIDATION_RESPONSE.
		note
			testing: "execution/isolated"
		local
			l_bridge: GRPC_PYTHON_BRIDGE
			l_ok: BOOLEAN
		do
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 9002)
			l_ok := l_bridge.initialize
			assert ({STRING_32} "bridge_initialized: " + l_bridge.last_error_message, l_ok)
			assert ("connected", l_bridge.is_connected)
			assert_round_trip (l_bridge, {STRING_32} "test_grpc_msg_001")
			assert_round_trip (l_bridge, {STRING_32} "test_grpc_msg_002")
			assert_round_trip (l_bridge, {STRING_32} "test_grpc_msg_003")
			l_bridge.close
			refute ("closed", l_bridge.is_connected)
		end

	test_grpc_bridge_handles_errors
			-- Nothing listening: initialize fails with the refusal, not connected.
		note
			testing: "execution/isolated"
		local
			l_bridge: GRPC_PYTHON_BRIDGE
		do
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 19999)
			refute ("initialize fails", l_bridge.initialize)
			refute ("not initialized", l_bridge.is_initialized)
			refute ("not connected", l_bridge.is_connected)
			assert ("has_error_set", l_bridge.has_error)
			assert ({STRING_32} "error names the refusal (WSA 10061): " + l_bridge.last_error_message,
				l_bridge.last_error_message.has_substring ({STRING_32} "10061"))
		end

	test_grpc_bridge_reconnects_after_close
			-- After close, the next send reconnects and still round-trips.
		note
			testing: "execution/isolated"
		local
			l_bridge: GRPC_PYTHON_BRIDGE
			l_ok: BOOLEAN
		do
			create l_bridge.make_with_host_port ({STRING_32} "localhost", 9002)
			l_ok := l_bridge.initialize
			assert ("initialized by host name", l_ok)
			assert_round_trip (l_bridge, {STRING_32} "first")
			l_bridge.close
			assert_round_trip (l_bridge, {STRING_32} "after_reconnect")
			assert ("connected again", l_bridge.is_connected)
			l_bridge.close
		end

end
