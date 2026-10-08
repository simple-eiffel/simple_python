note
	description: "[
		Real IPC round trips against python_ipc_server.py (TCP 127.0.0.1:9001,
		4-byte big-endian length + JSON), started by start_ipc_server_blocking.py
		and stopped by its PID only.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

class TEST_IPC_INTEGRATION_REAL

inherit
	PYTHON_BRIDGE_TEST_SUPPORT

feature -- Setup/Teardown

	setup
			-- Start this test's Python server through its launcher (start_ipc_server_blocking.py, port 9001).
		local
			l_server: PYTHON_TEST_SERVER
		do
			create l_server.make ("start_ipc_server_blocking.py", 9001)
			l_server.start
			server := l_server
			assert ({STRING_32} "ipc server started: " + l_server.last_launch_output, l_server.is_running)
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

	test_ipc_bridge_sends_to_python_server
			-- Two requests on one connection each get their own VALIDATION_RESPONSE.
		note
			testing: "execution/isolated"
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_ok: BOOLEAN
		do
			create l_bridge.make_with_pipe_name ({STRING_32} "\\.\pipe\simple_python_ipc")
			assert_integers_equal ("default port", 9001, l_bridge.port)
			l_ok := l_bridge.initialize
			assert ({STRING_32} "initialize connects: " + l_bridge.last_error_message, l_ok)
			assert ("connected", l_bridge.is_connected)
			assert_integers_equal ("one connection", 1, l_bridge.active_connections)
			assert_round_trip (l_bridge, {STRING_32} "test_ipc_msg_001")
			assert_round_trip (l_bridge, {STRING_32} "test_ipc_msg_002")
			l_bridge.close
			refute ("closed", l_bridge.is_connected)
			assert_integers_equal ("no connection", 0, l_bridge.active_connections)
		end

	test_ipc_bridge_handles_errors
			-- Nothing listening: initialize fails with the refusal, not connected.
		note
			testing: "execution/isolated"
		local
			l_bridge: IPC_PYTHON_BRIDGE
		do
			create l_bridge.make_with_port (19998)
			refute ("initialize fails", l_bridge.initialize)
			refute ("not initialized", l_bridge.is_initialized)
			refute ("not connected", l_bridge.is_connected)
			assert ("has error", l_bridge.has_error)
			assert ({STRING_32} "error names the refusal (WSA 10061): " + l_bridge.last_error_message,
				l_bridge.last_error_message.has_substring ({STRING_32} "10061"))
		end

	test_ipc_bridge_send_after_server_stops
			-- The server dies under an open connection: send fails, the bridge is in
			-- error and NOT connected (PYTHON_BRIDGE invariant error_implies_not_connected).
		note
			testing: "execution/isolated"
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
		do
			create l_bridge.make_with_port (9001)
			assert ("initialize connects", l_bridge.initialize)
			assert_round_trip (l_bridge, {STRING_32} "before_stop")
			if attached server as al_server then
				al_server.stop
			end
			create l_message.make ({STRING_32} "after_stop")
			refute ("send fails", l_bridge.send_message (l_message))
			assert ("has error", l_bridge.has_error)
			refute ("not connected after failure", l_bridge.is_connected)
			assert ("no stale reply", l_bridge.receive_message = Void)
			assert ("error message present", l_bridge.last_error_message.count > 0)
		end

end
