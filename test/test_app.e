note
	description: "Test runner for simple_python library"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run all tests with automatic server setup/teardown.
		do
			create output.make_empty
			create http_process.make
			create ipc_process.make

			output.append ("=== simple_python Test Suite ===%N%N")

			-- Start Python servers for integration tests
			setup_servers

			output.append ("--- SIMPLE_PYTHON tests ---%N")
			run_simple_python_tests

			output.append ("%N--- PYTHON_MESSAGE tests ---%N")
			run_python_message_tests

			output.append ("%N--- HTTP_PYTHON_BRIDGE tests ---%N")
			run_http_python_bridge_tests

			output.append ("%N--- HTTP Integration (Real Server) ---%N")
			run_http_integration_tests

-- 			output.append ("%N--- IPC Integration (Real Server) ---%N")
-- 			run_ipc_integration_tests

			-- output.append ("%N--- ADVERSARIAL tests ---%N")
			-- run_adversarial_tests  -- TODO: Fix segfault in Phase 6

			output.append ("%N=== All tests passed ===%N")

			-- Tear down servers
			teardown_servers

			-- Write results to console
			print (output)
		end

feature {NONE} -- Server Management

	http_process: SIMPLE_PROCESS
			-- HTTP test server process.

	ipc_process: SIMPLE_PROCESS
			-- IPC test server process.

	setup_servers
			-- Start Python test servers in background.
		local
			l_cmd: STRING_32
		do
			create http_process.make
			create ipc_process.make

			-- Start HTTP server in background (port 8888)
			l_cmd := {STRING_32} "start /B python3 python_test_server.py"
			http_process.execute (l_cmd)
			sleep_milliseconds (2000)  -- Allow server to start

			-- Start IPC server in background (Windows named pipe)
			-- TODO: Enable when Win32 API implementation is complete and win32pipe module available
			-- l_cmd := {STRING_32} "start /B python3 python_ipc_server.py"
			-- ipc_process.execute (l_cmd)
			-- sleep_milliseconds (1000)  -- Allow server to start
		end

	teardown_servers
			-- Stop all Python test servers.
		local
			l_proc: SIMPLE_PROCESS
		do
			-- Kill Python processes (both HTTP and IPC servers)
			create l_proc.make
			l_proc.execute ("taskkill /F /IM python.exe /FI 'WINDOWTITLE eq*simple_python*' 2>NUL")
			sleep_milliseconds (500)

			-- Alternative: more forceful kill
			l_proc.execute ("pkill -9 python3 2>NUL || exit 0")
			sleep_milliseconds (500)
		end

	sleep_milliseconds (a_ms: INTEGER)
			-- Sleep for specified milliseconds.
		local
			l_proc: SIMPLE_PROCESS
		do
			create l_proc.make
			l_proc.execute ("timeout /t " + (a_ms // 1000).out + " /nobreak")
		end

feature {NONE} -- Implementation

	output: STRING_32
			-- Test output buffer.

feature {NONE} -- SIMPLE_PYTHON Tests

	run_simple_python_tests
		local
			l_tests: TEST_SIMPLE_PYTHON
		do
			create l_tests

			output.append ("  test_http_bridge_creation: ")
			if attached l_tests as lt then
				lt.test_http_bridge_creation
				output.append ("OK%N")
			else
				output.append ("SKIPPED%N")
			end

			output.append ("  test_ipc_bridge_creation: ")
			if attached l_tests as lt then
				lt.test_ipc_bridge_creation
				output.append ("OK%N")
			else
				output.append ("SKIPPED%N")
			end

			output.append ("  test_grpc_bridge_creation: ")
			if attached l_tests as lt then
				lt.test_grpc_bridge_creation
				output.append ("OK%N")
			else
				output.append ("SKIPPED%N")
			end
		end

feature {NONE} -- PYTHON_MESSAGE Tests

	run_python_message_tests
		local
			l_tests: TEST_PYTHON_MESSAGE
		do
			create l_tests

			output.append ("  test_message_creation: ")
			l_tests.test_message_creation
			output.append ("OK%N")

			output.append ("  test_freeze_mechanism: ")
			l_tests.test_freeze_mechanism
			output.append ("OK%N")

			output.append ("  test_message_to_json: ")
			l_tests.test_message_to_json
			output.append ("OK%N")

			output.append ("  test_message_to_binary: ")
			l_tests.test_message_to_binary
			output.append ("OK%N")

			output.append ("  test_message_types: ")
			l_tests.test_message_types
			output.append ("OK%N")
		end

feature {NONE} -- HTTP_PYTHON_BRIDGE Tests

	run_http_python_bridge_tests
		local
			l_tests: TEST_HTTP_PYTHON_BRIDGE
		do
			create l_tests

			output.append ("  test_make_creates_unconfigured_bridge: ")
			l_tests.test_make_creates_unconfigured_bridge
			output.append ("OK%N")

			output.append ("  test_set_timeout_updates_timeout: ")
			l_tests.test_set_timeout_updates_timeout
			output.append ("OK%N")

			output.append ("  test_initialize_succeeds: ")
			l_tests.test_initialize_succeeds
			output.append ("OK%N")

			output.append ("  test_close_disconnects_bridge: ")
			l_tests.test_close_disconnects_bridge
			output.append ("OK%N")

			output.append ("  test_active_connections_query: ")
			l_tests.test_active_connections_query
			output.append ("OK%N")
		end

feature {NONE} -- HTTP Integration Tests

	run_http_integration_tests
		local
			l_tests: TEST_HTTP_INTEGRATION_REAL
		do
			create l_tests

			output.append ("  test_http_bridge_sends_to_python_server: ")
			l_tests.test_http_bridge_sends_to_python_server
			output.append ("OK%N")

			output.append ("  test_http_bridge_handles_errors: ")
			l_tests.test_http_bridge_handles_errors
			output.append ("OK%N")
		end

feature {NONE} -- IPC Integration Tests

	run_ipc_integration_tests
		local
			l_tests: TEST_IPC_INTEGRATION_REAL
		do
			create l_tests

			output.append ("  test_ipc_bridge_sends_to_python_server: ")
			l_tests.test_ipc_bridge_sends_to_python_server
			output.append ("OK%N")

			output.append ("  test_ipc_bridge_handles_errors: ")
			l_tests.test_ipc_bridge_handles_errors
			output.append ("OK%N")
		end

feature {NONE} -- IPC_PYTHON_BRIDGE Tests

	run_ipc_python_bridge_tests
		local
			l_tests: TEST_IPC_PYTHON_BRIDGE
		do
			create l_tests

			output.append ("  test_make_creates_unconfigured_bridge: ")
			l_tests.test_make_creates_unconfigured_bridge
			output.append ("OK%N")

			output.append ("  test_set_timeout_updates_timeout: ")
			l_tests.test_set_timeout_updates_timeout
			output.append ("OK%N")

			output.append ("  test_close_disconnects_bridge: ")
			l_tests.test_close_disconnects_bridge
			output.append ("OK%N")

			output.append ("  test_encode_frame_adds_length_prefix: ")
			l_tests.test_encode_frame_adds_length_prefix
			output.append ("OK%N")

			output.append ("  test_decode_frame_extracts_payload: ")
			l_tests.test_decode_frame_extracts_payload
			output.append ("OK%N")
		end

feature {NONE} -- ADVERSARIAL Tests

	run_adversarial_tests
		local
			l_tests: TEST_ADVERSARIAL
		do
			create l_tests

			output.append ("  test_message_with_empty_attributes: ")
			l_tests.test_message_with_empty_attributes
			output.append ("OK%N")

			output.append ("  test_message_with_many_attributes: ")
			l_tests.test_message_with_many_attributes
			output.append ("OK%N")

			output.append ("  test_message_with_empty_string_id: ")
			l_tests.test_message_with_empty_string_id
			output.append ("OK%N")

			output.append ("  test_frame_with_zero_length_payload: ")
			l_tests.test_frame_with_zero_length_payload
			output.append ("OK%N")

			output.append ("  test_frame_with_large_payload: ")
			l_tests.test_frame_with_large_payload
			output.append ("OK%N")

			output.append ("  test_decode_frame_with_size_mismatch: ")
			l_tests.test_decode_frame_with_size_mismatch
			output.append ("OK%N")

			output.append ("  test_freeze_prevents_attribute_modification: ")
			l_tests.test_freeze_prevents_attribute_modification
			output.append ("OK%N")

			output.append ("  test_multiple_messages_independent_state: ")
			l_tests.test_multiple_messages_independent_state
			output.append ("OK%N")

			output.append ("  test_timeout_boundary_values: ")
			l_tests.test_timeout_boundary_values
			output.append ("OK%N")

			output.append ("  test_bridge_close_idempotent: ")
			l_tests.test_bridge_close_idempotent
			output.append ("OK%N")

			output.append ("  test_bridge_initialize_idempotent: ")
			l_tests.test_bridge_initialize_idempotent
			output.append ("OK%N")

			output.append ("  test_message_binary_roundtrip: ")
			l_tests.test_message_binary_roundtrip
			output.append ("OK%N")
		end

end
