note
	description: "Real gRPC integration tests with TCP socket communication"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_GRPC_INTEGRATION_REAL

inherit
	TEST_SET_BASE

feature -- Setup/Teardown

	setup
			-- Start Python gRPC server before each test.
		local
			l_proc: SIMPLE_PROCESS
		do
			create grpc_process.make
			create l_proc.make

			-- Start gRPC server using blocking launcher (waits for port 9002 listening)
			l_proc.execute ({STRING_32} "python3 " + server_script_path + "start_grpc_server_blocking.py 9002")

			-- Give server extra time to be ready
			sleep_milliseconds (1000)
		end

	teardown
			-- Stop Python gRPC server after each test.
		local
			l_proc: SIMPLE_PROCESS
		do
			-- Kill Python gRPC server process
			create l_proc.make
			l_proc.execute ("taskkill /F /IM python.exe 2>NUL")
			sleep_milliseconds (500)

			-- Fallback: pkill
			l_proc.execute ("pkill -9 python3 2>NUL || exit 0")
			sleep_milliseconds (500)
		end

feature {NONE} -- Process Management

	grpc_process: detachable SIMPLE_PROCESS
			-- gRPC server process handle.

	server_script_path: STRING_32
			-- Path to the directory containing server startup scripts.
		do
			Result := {STRING_32} "D:\prod\simple_python\"
		end

	sleep_milliseconds (a_ms: INTEGER)
			-- Sleep for specified milliseconds.
		local
			l_proc: SIMPLE_PROCESS
		do
			create l_proc.make
			l_proc.execute ("timeout /t " + (a_ms // 1000).out + " /nobreak")
		end

feature -- Tests

	test_grpc_bridge_sends_to_python_server
		note
			testing: "execution/isolated"
		local
			l_bridge: GRPC_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
			-- Send a message to the running Python gRPC server via TCP socket.
			-- Create bridge pointing to Python gRPC server port
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 9002)

			-- Initialize bridge
			l_result := l_bridge.initialize
			assert ("bridge_initialized", l_result)

			-- Create a test message
			create l_message.make ({STRING_32} "test_grpc_msg_001")

			-- Send message to Python server via gRPC
			l_result := l_bridge.send_message (l_message)
			assert ("message_sent_successfully", l_result)

			-- Close bridge
			l_bridge.close
		end

	test_grpc_bridge_handles_errors
		note
			testing: "execution/isolated"
		local
			l_bridge: GRPC_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
			-- Test error handling when Python gRPC server is unreachable.
			-- Create bridge pointing to non-listening port
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 19999)

			-- Initialize bridge
			l_result := l_bridge.initialize
			assert ("bridge_initialized", l_result)

			-- Create a test message
			create l_message.make ({STRING_32} "test_grpc_msg_002")

			-- Try to send message (should fail gracefully)
			l_result := l_bridge.send_message (l_message)
			assert ("error_handled_gracefully", not l_result)

			-- Check that error flag is set
			assert ("has_error_set", l_bridge.has_error)
			assert ("error_message_present", l_bridge.last_error_message.count > 0)
		end

end
