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
			-- Start this test's Python server through its launcher (start_grpc_server_blocking.py, port 9002).
		local
			l_server: PYTHON_TEST_SERVER
		do
			create l_server.make ("start_grpc_server_blocking.py", 9002)
			l_server.start
			server := l_server
			-- Give server extra time to be ready
			sleep_milliseconds (1000)
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

	server_script_path: STRING_32
			-- Path to the directory containing server startup scripts.
		do
			Result := {STRING_32} "./"
		end

	sleep_milliseconds (a_ms: INTEGER)
			-- Sleep for `a_ms' milliseconds.
		require
			non_negative: a_ms >= 0
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (a_ms.to_integer_64 * 1_000_000)
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
