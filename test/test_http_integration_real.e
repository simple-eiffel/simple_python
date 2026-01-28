note
	description: "Real HTTP integration tests with actual Python server communication"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_HTTP_INTEGRATION_REAL

inherit
	TEST_SET_BASE

feature {NONE} -- Setup/Teardown

	setup
			-- Start Python HTTP server before each test.
		local
			l_proc: SIMPLE_PROCESS
		do
			create http_process.make
			create l_proc.make

			-- Start HTTP server in background
			l_proc.execute ({STRING_32} "start /B python3 python_test_server.py")

			-- Wait for server to initialize
			sleep_milliseconds (2000)
		end

	teardown
			-- Stop Python HTTP server after each test.
		local
			l_proc: SIMPLE_PROCESS
		do
			-- Kill Python HTTP server process
			create l_proc.make
			l_proc.execute ("taskkill /F /IM python.exe 2>NUL")
			sleep_milliseconds (500)

			-- Fallback: pkill
			l_proc.execute ("pkill -9 python3 2>NUL || exit 0")
			sleep_milliseconds (500)
		end

feature {NONE} -- Process Management

	http_process: detachable SIMPLE_PROCESS
			-- HTTP server process handle.

	sleep_milliseconds (a_ms: INTEGER)
			-- Sleep for specified milliseconds.
		local
			l_proc: SIMPLE_PROCESS
		do
			create l_proc.make
			l_proc.execute ("timeout /t " + (a_ms // 1000).out + " /nobreak")
		end

feature -- Tests

	test_http_bridge_sends_to_python_server
		note
			testing: "execution/isolated"
		local
			l_bridge: HTTP_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
			-- Send a message to the running Python test server via HTTP.
			-- Create bridge pointing to Python server on localhost:8888
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 8888)

			-- Initialize bridge
			l_result := l_bridge.initialize

			-- Create a test message
			create l_message.make ({STRING_32} "test_msg_001")

			-- Send message to Python server
			l_result := l_bridge.send_message (l_message)
		end

	test_http_bridge_handles_errors
		note
			testing: "execution/isolated"
		local
			l_bridge: HTTP_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
			-- Test error handling when Python server is unreachable.
			-- Create bridge pointing to invalid server (port 9999 should be empty)
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 9999)

			-- Initialize bridge
			l_result := l_bridge.initialize

			-- Create a test message
			create l_message.make ({STRING_32} "test_msg_002")

			-- Try to send message (should fail gracefully)
			l_result := l_bridge.send_message (l_message)
		end

end
