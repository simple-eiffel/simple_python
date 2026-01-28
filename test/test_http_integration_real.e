note
	description: "Real HTTP integration tests with actual Python server communication"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_HTTP_INTEGRATION_REAL

inherit
	TEST_SET_BASE

feature {NONE} -- Logger

	logger: SIMPLE_LOGGER
		once
			create Result.make_to_file ("logs/simple_python.log")
		end

feature -- Setup/Teardown

	setup
			-- Setup for HTTP integration tests.
			-- Automatically starts Python HTTP server on port 8889 using VBScript launcher.
		local
			l_proc: SIMPLE_PROCESS
		do
			logger.log_info ("TEST_HTTP_INTEGRATION_REAL setup: START")

			create http_process.make
			create l_proc.make

			-- Start HTTP server using blocking launcher (waits for port to be listening)
			logger.log_info ("Starting Python HTTP server on port 8889 using blocking launcher...")
			l_proc.execute ({STRING_32} "python3 ./start_http_server_blocking.py 8889")

			logger.log_info ("TEST_HTTP_INTEGRATION_REAL setup: END")
		end

	teardown
			-- Stop Python HTTP server after each test.
		local
			l_proc: SIMPLE_PROCESS
		do
			logger.log_info ("TEST_HTTP_INTEGRATION_REAL teardown: START")

			-- Kill Python HTTP server process - use /T flag to kill child processes too
			create l_proc.make
			logger.log_info ("Killing Python processes: taskkill /F /T /IM python.exe")
			l_proc.execute ("taskkill /F /T /IM python.exe 2>NUL")
			sleep_milliseconds (800)

			-- Also try python3
			logger.log_info ("Killing python3: taskkill /F /T /IM python3.exe")
			l_proc.execute ("taskkill /F /T /IM python3.exe 2>NUL")
			sleep_milliseconds (500)

			-- Fallback: pkill with stronger options
			logger.log_info ("Fallback kill: pkill -9 python")
			l_proc.execute ("pkill -9 python || true")
			sleep_milliseconds (500)

			logger.log_info ("TEST_HTTP_INTEGRATION_REAL teardown: END")
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
			l_response: detachable PYTHON_MESSAGE
			l_msg: STRING_32
			l_err_msg: STRING_32
		do
			logger.log_info ("TEST: test_http_bridge_sends_to_python_server START")
			logger.log_info ("NOTE: Requires Python HTTP server running on port 8889")
			logger.log_info ("If server not available, this test will be skipped")

			-- Send a message to the running Python test server via HTTP and validate round-trip.
			-- Create bridge pointing to Python server on localhost:8889
			logger.log_info ("Creating HTTP bridge to 127.0.0.1:8889")
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 8889)

			-- Initialize bridge
			logger.log_info ("Initializing bridge")
			l_result := l_bridge.initialize
			assert ("bridge_initialized", l_result)
			logger.log_info ("Bridge initialized successfully")

			-- Create a test message with specific ID
			logger.log_info ("Creating validation request message: test_msg_001")
			create l_message.make ({STRING_32} "test_msg_001")

			-- Send message to Python server
			logger.log_info ("Sending message to Python server")
			l_result := l_bridge.send_message (l_message)

			-- If send failed, log the error
			if not l_result then
				logger.log_error ("Message send FAILED!")
				logger.log_error ("Bridge error state: has_error=" + l_bridge.has_error.out)
				l_err_msg := {STRING_32} "Bridge error message: " + l_bridge.last_error_message
				logger.log_error (l_err_msg.to_string_8)
			end

			assert ("message_sent_successfully", l_result)
			logger.log_info ("Message sent successfully")

			-- Receive the response from Python server
			logger.log_info ("Receiving response from bridge")
			l_response := l_bridge.receive_message

			-- Validate response is not void (server acknowledged)
			logger.log_info ("Validating response not void")
			assert ("response_not_void", l_response /= Void)

			-- Validate response message ID matches what we sent
			if attached l_response then
				l_msg := {STRING_32} "Response received with ID: " + l_response.message_id + {STRING_32} ", type: " + l_response.message_type
				logger.log_info (l_msg.to_string_8)
				assert ("response_message_id_matches", l_response.message_id.same_string ({STRING_32} "test_msg_001"))

				-- Validate response type is VALIDATION_RESPONSE
				assert ("response_type_correct", l_response.message_type.same_string ({STRING_32} "VALIDATION_RESPONSE"))
				logger.log_info ("Response type validated")

				-- Validate response has attributes (Python server sent validation result)
				assert ("response_has_attributes", l_response.attribute_count > 0)
				logger.log_info ("Response has attributes: count = " + l_response.attribute_count.out)

				-- Validate specific attribute: result should be "PASS"
				if l_response.has_attribute ({STRING_32} "result") then
					if attached l_response.get_attribute ({STRING_32} "result") as l_result_attr then
						l_msg := {STRING_32} "Result attribute found: " + l_result_attr.as_string_32
						logger.log_info (l_msg.to_string_8)
						assert ("response_result_is_pass", l_result_attr.as_string_32.same_string ({STRING_32} "PASS"))
					end
				end
			end

			logger.log_info ("TEST: test_http_bridge_sends_to_python_server END - PASSED")
		end

	test_http_bridge_handles_errors
		note
			testing: "execution/isolated"
		local
			l_bridge: HTTP_PYTHON_BRIDGE
			l_message: PYTHON_VALIDATION_REQUEST
			l_result: BOOLEAN
			l_err_msg: STRING_32
		do
			logger.log_info ("TEST: test_http_bridge_handles_errors START")

			-- Test error handling when Python server is unreachable.
			-- Create bridge pointing to invalid server (port 9999 should be empty)
			logger.log_info ("Creating HTTP bridge to 127.0.0.1:9999 (should fail)")
			create l_bridge.make_with_host_port ({STRING_32} "127.0.0.1", 9999)

			-- Initialize bridge
			logger.log_info ("Initializing bridge")
			l_result := l_bridge.initialize
			assert ("bridge_initialized", l_result)

			-- Create a test message
			logger.log_info ("Creating validation request message: test_msg_002")
			create l_message.make ({STRING_32} "test_msg_002")

			-- Try to send message to non-existent server (should fail gracefully)
			logger.log_info ("Sending message to non-existent server (should fail)")
			l_result := l_bridge.send_message (l_message)
			assert ("send_fails_gracefully", not l_result)
			logger.log_info ("Send failed as expected")

			-- Validate error was recorded
			assert ("error_flag_set", l_bridge.has_error)
			logger.log_info ("Error flag set correctly")

			-- Validate error message is informative
			assert ("error_message_not_empty", l_bridge.last_error_message.count > 0)
			l_err_msg := {STRING_32} "Error message: " + l_bridge.last_error_message
			logger.log_info (l_err_msg.to_string_8)

			logger.log_info ("TEST: test_http_bridge_handles_errors END - PASSED")
		end

end
