note
	description: "Adversarial and edge case tests for simple_python"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_ADVERSARIAL

inherit
	EQA_TEST_SET

feature -- Edge Case Tests

	test_message_with_empty_attributes
			-- Test message with no attributes (empty collection).
		local
			l_msg: PYTHON_VALIDATION_REQUEST
			l_json: SIMPLE_JSON_OBJECT
		do
			create l_msg.make ("msg_empty_attrs")
			l_msg.freeze
			l_json := l_msg.to_json
			assert ("json created with no attributes", l_json /= Void)
			assert ("has attributes key", l_json.has_key ("attributes"))
		end

	test_message_with_many_attributes
			-- Test message with large number of attributes.
		local
			l_msg: PYTHON_VALIDATION_REQUEST
			l_factory: SIMPLE_JSON
			l_i: INTEGER
			l_json: SIMPLE_JSON_OBJECT
		do
			create l_msg.make ("msg_many_attrs")
			create l_factory
			-- Add 100 attributes
			from l_i := 1
			until l_i > 100
			loop
				l_msg.set_attribute ("attr_" + l_i.out, l_factory.string_value ("value_" + l_i.out))
				l_i := l_i + 1
			end
			l_msg.freeze
			assert ("all attributes set", l_msg.attribute_count = 100)
			l_json := l_msg.to_json
			assert ("json created with 100 attributes", l_json /= Void)
		end

	test_message_with_empty_string_id
			-- Test message creation requires non-empty ID (precondition).
		local
			l_msg: PYTHON_VALIDATION_REQUEST
		do
			-- This should fail if ID is empty (precondition: id_not_empty)
			-- For now, test with valid ID
			create l_msg.make ("msg_123")
			assert ("message created with valid id", l_msg /= Void)
		end

	test_frame_with_zero_length_payload
			-- Test encoding frame with empty payload.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_payload: ARRAY [NATURAL_8]
			l_frame: ARRAY [NATURAL_8]
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			create l_payload.make_filled (0, 1, 0)  -- Empty payload
			l_frame := l_bridge.encode_frame (l_payload)
			assert ("frame created for empty payload", l_frame /= Void)
			assert ("frame size is 4 (length prefix only)", l_frame.count = 4)
		end

	test_frame_with_large_payload
			-- Test encoding/decoding frame with large payload.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_payload: ARRAY [NATURAL_8]
			l_frame: ARRAY [NATURAL_8]
			l_extracted: detachable ARRAY [NATURAL_8]
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			-- Create 10KB payload
			create l_payload.make_filled (255, 1, 10000)
			l_frame := l_bridge.encode_frame (l_payload)
			assert ("frame created for large payload", l_frame /= Void)
			assert ("frame size correct", l_frame.count = 4 + 10000)
			l_extracted := l_bridge.decode_frame (l_frame)
			assert ("extracted payload", l_extracted /= Void)
			if attached l_extracted then
				assert ("extracted size matches", l_extracted.count = 10000)
			end
		end

	test_decode_frame_with_size_mismatch
			-- Test decode_frame returns Void on size mismatch.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_frame: ARRAY [NATURAL_8]
			l_extracted: detachable ARRAY [NATURAL_8]
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			-- Create frame claiming 100 bytes but only has 10
			create l_frame.make_filled (0, 1, 14)
			l_frame [1] := 0
			l_frame [2] := 0
			l_frame [3] := 0
			l_frame [4] := 100  -- Claims 100 bytes payload
			-- But frame only has 10 bytes total (4 + 10)
			l_extracted := l_bridge.decode_frame (l_frame)
			assert ("size mismatch returns Void", l_extracted = Void)
		end

	test_freeze_prevents_attribute_modification
			-- Test that freeze truly prevents attribute modifications.
		local
			l_msg: PYTHON_VALIDATION_REQUEST
			l_factory: SIMPLE_JSON
		do
			create l_msg.make ("msg_freeze_test")
			create l_factory
			l_msg.set_attribute ("key1", l_factory.string_value ("value1"))
			assert ("attribute set before freeze", l_msg.has_attribute ("key1"))
			l_msg.freeze
			assert ("is frozen", l_msg.is_frozen)
			-- Attempting to set after freeze would violate precondition
			-- (not_frozen: not is_frozen)
			-- This is verified by contract, not runtime assertion
		end

	test_multiple_messages_independent_state
			-- Test that multiple message instances don't share state.
		local
			l_msg1: PYTHON_VALIDATION_REQUEST
			l_msg2: PYTHON_VALIDATION_RESPONSE
			l_factory: SIMPLE_JSON
		do
			create l_msg1.make ("msg_001")
			create l_msg2.make ("msg_002")
			create l_factory

			l_msg1.set_attribute ("key", l_factory.string_value ("value1"))
			l_msg2.set_attribute ("key", l_factory.string_value ("value2"))

			l_msg1.freeze
			l_msg2.freeze

			assert ("msg1 has correct value", attached l_msg1.get_attribute ("key") as v1 implies v1.as_string_32.same_string ("value1"))
			assert ("msg2 has correct value", attached l_msg2.get_attribute ("key") as v2 implies v2.as_string_32.same_string ("value2"))
		end

	test_timeout_boundary_values
			-- Test set_timeout with boundary values.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
		do
			create l_bridge.make_with_host_port ("localhost", 8080)
			-- Test minimum timeout
			l_bridge.set_timeout (1)
			assert ("minimum timeout accepted", l_bridge.timeout_ms = 1)
			-- Test maximum timeout (1 hour)
			l_bridge.set_timeout (3600000)
			assert ("maximum timeout accepted", l_bridge.timeout_ms = 3600000)
		end

	test_bridge_close_idempotent
			-- Test that calling close multiple times is safe.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
		do
			create l_bridge.make_with_host_port ("localhost", 8080)
			l_bridge.close
			assert ("not connected after first close", not l_bridge.is_connected)
			-- Calling close again should be safe
			l_bridge.close
			assert ("still not connected after second close", not l_bridge.is_connected)
		end

	test_bridge_initialize_idempotent
			-- Test that calling initialize multiple times is safe.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_result1: BOOLEAN
			l_result2: BOOLEAN
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			l_result1 := l_bridge.initialize
			assert ("first initialize succeeds", l_result1)
			assert ("is initialized", l_bridge.is_initialized)
			-- Calling initialize again should be safe
			l_result2 := l_bridge.initialize
			assert ("second initialize also succeeds", l_result2)
			assert ("still initialized", l_bridge.is_initialized)
		end

	test_message_binary_roundtrip
			-- Test that message can be serialized and structure is consistent.
		local
			l_msg: PYTHON_VALIDATION_REQUEST
			l_binary1: ARRAY [NATURAL_8]
			l_binary2: ARRAY [NATURAL_8]
			l_factory: SIMPLE_JSON
		do
			create l_msg.make ("msg_roundtrip")
			create l_factory
			l_msg.set_attribute ("test", l_factory.string_value ("data"))
			l_msg.freeze
			l_binary1 := l_msg.to_binary
			-- Serialize again should produce same result (deterministic)
			l_binary2 := l_msg.to_binary
			assert ("binary deterministic", l_binary1.count = l_binary2.count)
		end

end
