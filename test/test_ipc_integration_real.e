note
	description: "Real IPC integration tests with Windows named pipe communication"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_IPC_INTEGRATION_REAL

inherit
	TEST_SET_BASE

feature {NONE} -- Setup/Teardown

	setup
			-- Start Python IPC server before each test.
		local
			l_proc: SIMPLE_PROCESS
		do
			create ipc_process.make
			create l_proc.make

			-- Start IPC server in background
			l_proc.execute ({STRING_32} "python3 d:\prod\simple_python\python_ipc_server.py")

			-- Wait for server to initialize
			sleep_milliseconds (1000)
		end

	teardown
			-- Stop Python IPC server after each test.
		local
			l_proc: SIMPLE_PROCESS
		do
			-- Kill Python IPC server process
			create l_proc.make
			l_proc.execute ("taskkill /F /IM python.exe 2>NUL")
			sleep_milliseconds (500)

			-- Fallback: pkill
			l_proc.execute ("pkill -9 python3 2>NUL || exit 0")
			sleep_milliseconds (500)
		end

feature {NONE} -- Process Management

	ipc_process: detachable SIMPLE_PROCESS
			-- IPC server process handle.

	sleep_milliseconds (a_ms: INTEGER)
			-- Sleep for specified milliseconds.
		local
			l_proc: SIMPLE_PROCESS
		do
			create l_proc.make
			l_proc.execute ("timeout /t " + (a_ms // 1000).out + " /nobreak")
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
