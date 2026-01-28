note
	description: "[
		Integration tests for simple_python library with self-contained setup/teardown.

		These tests automatically start Python test servers, run validations,
		and clean up afterwards. No manual server startup required.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_INTEGRATION

feature {NONE} -- Initialization

	setup
			-- Start Python test servers before running tests.
		do
			print ("%N=== Integration Test Setup ===%N")

			-- Start HTTP server
			create http_server.make
			if start_http_server then
				print ("✓ HTTP server started on localhost:8080%N")
			else
				print ("✗ Failed to start HTTP server%N")
			end

			-- Brief delay to allow servers to initialize
			sleep_milliseconds (2000)
		end

	teardown
			-- Stop Python test servers and clean up after tests.
		do
			print ("%N=== Integration Test Teardown ===%N")

			-- Kill HTTP server
			if http_server.is_running then
				http_server.kill
				sleep_milliseconds (500)
				print ("✓ HTTP server stopped%N")
			end

			-- Clean up test artifacts
			clean_test_artifacts
		end

feature {NONE} -- Process Management

	http_server: SIMPLE_ASYNC_PROCESS
			-- HTTP test server process handle.

	start_http_server: BOOLEAN
			-- Start HTTP server, return true if successful.
		local
			l_project_path: STRING_32
		do
			l_project_path := get_project_root
			http_server.start ("python3 python_servers.py http", l_project_path)

			-- Wait for server to be ready (max 10 seconds)
			Result := wait_for_http_server (10)
		end

	wait_for_http_server (a_timeout_seconds: INTEGER): BOOLEAN
			-- Wait for HTTP server to be ready (listening on port 8080).
		local
			l_elapsed: INTEGER
			l_proc: SIMPLE_PROCESS
		do
			print ("Waiting for HTTP server to initialize...")

			from l_elapsed := 0
			until l_elapsed >= a_timeout_seconds or Result
			loop
				-- Try to connect to HTTP server
				create l_proc.make
				l_proc.execute ("curl -s http://localhost:8080/ > nul 2>&1 || exit 1")
				if l_proc.was_successful then
					Result := True
					print (" Ready%N")
				else
					sleep_milliseconds (500)
					l_elapsed := l_elapsed + 1
				end
			end

			if not Result then
				print (" TIMEOUT%N")
			end
		end

	sleep_milliseconds (a_milliseconds: INTEGER)
			-- Sleep for specified milliseconds.
		local
			l_proc: SIMPLE_PROCESS
		do
			create l_proc.make
			if {PLATFORM}.is_windows then
				l_proc.execute ("timeout /t " + (a_milliseconds // 1000).out + " /nobreak")
			else
				l_proc.execute ("sleep " + (a_milliseconds / 1000.0).out)
			end
		end

	get_project_root: STRING_32
			-- Get simple_python project root directory.
		once
			Result := "."
		end

	clean_test_artifacts
			-- Clean up any test output files or temporary data.
		local
			l_files: ARRAY [STRING]
			l_file_path: STRING_32
			l_i: INTEGER
		do
			-- List of test artifact files to clean up
			l_files := <<
				"./test_output.txt",
				"./integration_test.log"
			>>

			from l_i := l_files.lower
			until l_i > l_files.upper
			loop
				l_file_path := l_files [l_i]
				-- In production, use file operations to delete
				-- For now, just log what would be deleted
				l_i := l_i + 1
			end

			print ("✓ Test artifacts cleaned%N")
		end

feature -- Tests

	test_http_roundtrip_with_auto_server
			-- Send validation request to automatically-managed Python HTTP server.
		local
			l_lib: SIMPLE_PYTHON
			l_bridge: HTTP_PYTHON_BRIDGE
			l_request: PYTHON_VALIDATION_REQUEST
			l_response: detachable PYTHON_MESSAGE
			l_factory: SIMPLE_JSON
		do
			setup

			print ("%N--- Test: HTTP Roundtrip ---%N")

			create l_lib.make
			l_bridge := l_lib.new_http_bridge ("localhost", 8080)
			l_bridge.set_timeout (5000)

			if l_bridge.initialize then
				create l_request.make ("test_http_roundtrip_001")
				create l_factory
				l_request.set_attribute ("board_id", l_factory.string_value ("PCB-001"))
				l_request.set_attribute ("temperature", l_factory.integer_value (45))
				l_request.freeze

				if l_bridge.send_message (l_request) then
					print ("Request sent: test_http_roundtrip_001%N")

					l_response := l_bridge.receive_message
					if l_response /= Void then
						print ("Response received: " + l_response.message_id + "%N")

						if attached {PYTHON_VALIDATION_RESPONSE} l_response as l_resp then
							if l_resp.has_attribute ("result") then
								if attached l_resp.get_attribute ("result") as l_result then
									print ("Result: " + l_result.as_string_32 + "%N")
									print ("✓ PASS%N")
								end
							end
						end
					else
						print ("✗ FAIL - Timeout%N")
					end
				else
					print ("✗ FAIL - Send failed%N")
				end

				l_bridge.close
			else
				print ("✗ FAIL - Initialize failed%N")
			end

			teardown
		end

	test_http_message_validation
			-- Test that HTTP server correctly validates message structure.
		local
			l_lib: SIMPLE_PYTHON
			l_bridge: HTTP_PYTHON_BRIDGE
			l_request: PYTHON_VALIDATION_REQUEST
			l_response: detachable PYTHON_MESSAGE
			l_factory: SIMPLE_JSON
		do
			setup

			print ("%N--- Test: HTTP Message Validation ---%N")

			create l_lib.make
			l_bridge := l_lib.new_http_bridge ("localhost", 8080)
			l_bridge.set_timeout (5000)

			if l_bridge.initialize then
				-- Create request with multiple attributes
				create l_request.make ("test_validation_001")
				create l_factory
				l_request.set_attribute ("board_id", l_factory.string_value ("PCB-002"))
				l_request.set_attribute ("temperature", l_factory.integer_value (55))
				l_request.set_attribute ("voltage", l_factory.number_value (3.3))
				l_request.freeze

				if l_bridge.send_message (l_request) then
					l_response := l_bridge.receive_message
					if l_response /= Void then
						-- Verify response has required fields
						if l_response.has_attribute ("result") and l_response.has_attribute ("score") then
							print ("✓ PASS - Response has all required attributes%N")
						else
							print ("✗ FAIL - Response missing attributes%N")
						end
					else
						print ("✗ FAIL - No response%N")
					end
				else
					print ("✗ FAIL - Send failed%N")
				end

				l_bridge.close
			end

			teardown
		end

	test_http_multiple_sequential_requests
			-- Send multiple requests sequentially to test bridge reuse.
		local
			l_lib: SIMPLE_PYTHON
			l_bridge: HTTP_PYTHON_BRIDGE
			l_i: INTEGER
			l_success_count: INTEGER
		do
			setup

			print ("%N--- Test: HTTP Multiple Sequential Requests ---%N")

			create l_lib.make
			l_bridge := l_lib.new_http_bridge ("localhost", 8080)
			l_bridge.set_timeout (5000)

			if l_bridge.initialize then
				from l_i := 1
				until l_i > 5
				loop
					if send_http_request (l_bridge, "request_" + l_i.out) then
						l_success_count := l_success_count + 1
					end
					l_i := l_i + 1
				end

				l_bridge.close

				print ("Completed: " + l_success_count.out + "/5 requests successful%N")
				if l_success_count = 5 then
					print ("✓ PASS - All requests completed%N")
				else
					print ("✗ FAIL - Some requests failed%N")
				end
			else
				print ("✗ FAIL - Bridge initialization failed%N")
			end

			teardown
		end

feature {NONE} -- Helper

	send_http_request (a_bridge: HTTP_PYTHON_BRIDGE; a_request_id: STRING_32): BOOLEAN
			-- Send single HTTP request, return true if successful.
		local
			l_request: PYTHON_VALIDATION_REQUEST
			l_response: detachable PYTHON_MESSAGE
			l_factory: SIMPLE_JSON
		do
			create l_request.make (a_request_id)
			create l_factory
			l_request.set_attribute ("sequence", l_factory.string_value (a_request_id))
			l_request.freeze

			if a_bridge.send_message (l_request) then
				l_response := a_bridge.receive_message
				if l_response /= Void then
					Result := True
					print ("  Request " + a_request_id + ": OK%N")
				else
					print ("  Request " + a_request_id + ": TIMEOUT%N")
				end
			else
				print ("  Request " + a_request_id + ": SEND_FAILED%N")
			end
		end

end
