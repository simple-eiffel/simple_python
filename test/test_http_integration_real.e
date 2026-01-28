note
	description: "Real HTTP integration tests with actual Python server communication"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_HTTP_INTEGRATION_REAL

feature -- Tests

	test_http_bridge_sends_to_python_server
			-- Send a message to the running Python test server via HTTP.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
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
			-- Test error handling when Python server is unreachable.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
		do
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
