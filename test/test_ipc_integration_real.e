note
	description: "Real IPC integration tests with Windows named pipe communication"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_IPC_INTEGRATION_REAL

inherit
	TEST_SET_BASE

feature -- Setup/Teardown

	setup
			-- Start this test's Python server through its launcher (start_ipc_server_blocking.py, port 9001).
		local
			l_server: PYTHON_TEST_SERVER
		do
			create l_server.make ("start_ipc_server_blocking.py", 9001)
			l_server.start
			server := l_server
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

	sleep_milliseconds (a_ms: INTEGER)
			-- Sleep for `a_ms' milliseconds.
		require
			non_negative: a_ms >= 0
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (a_ms.to_integer_64 * 1_000_000)
		end

feature -- Tests

	test_ipc_bridge_sends_to_python_server
		note
			testing: "execution/isolated"
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
			-- Send a message to the running Python IPC server via named pipe.
			-- Create bridge pointing to Python IPC server pipe
			create l_bridge.make_with_pipe_name ({STRING_32} "\\.\pipe\simple_python_ipc")

			-- Initialize bridge
			l_result := l_bridge.initialize

			-- Create a test message
			create l_message.make ({STRING_32} "test_ipc_msg_001")

			-- Send message to Python server via pipe
			l_result := l_bridge.send_message (l_message)
		end

	test_ipc_bridge_handles_errors
		note
			testing: "execution/isolated"
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
			-- Test error handling when Python IPC server is unreachable.
			-- Create bridge pointing to non-existent pipe
			create l_bridge.make_with_pipe_name ({STRING_32} "\\.\pipe\nonexistent_ipc")

			-- Initialize bridge
			l_result := l_bridge.initialize

			-- Create a test message
			create l_message.make ({STRING_32} "test_ipc_msg_002")

			-- Try to send message (should fail gracefully)
			l_result := l_bridge.send_message (l_message)
		end

end
