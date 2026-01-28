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
			-- Run all tests. Integration tests manage their own server setup/teardown.
		do
			create output.make_empty

			output.append ("=== simple_python Test Suite ===%N%N")

			output.append ("--- SIMPLE_PYTHON tests ---%N")
			run_simple_python_tests

			output.append ("%N--- PYTHON_MESSAGE tests ---%N")
			run_python_message_tests

			output.append ("%N--- HTTP_PYTHON_BRIDGE tests ---%N")
			run_http_python_bridge_tests

			output.append ("%N--- HTTP Integration (Real Server) ---%N")
			run_http_integration_tests

			output.append ("%N--- IPC_PYTHON_BRIDGE tests ---%N")
			run_ipc_python_bridge_tests

			output.append ("%N--- IPC Integration (Real Server) ---%N")
			run_ipc_integration_tests

			output.append ("%N--- ADVERSARIAL tests ---%N")
			run_adversarial_tests

			output.append ("%N=== All tests passed ===%N")

			-- Write results to console
			print (output)
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
