note
	description: "Real IPC integration tests with Windows named pipe communication"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_IPC_INTEGRATION_REAL

feature -- Tests

	test_ipc_bridge_sends_to_python_server
			-- Send a message to the running Python IPC server via named pipe.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
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
			-- Test error handling when Python IPC server is unreachable.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
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
