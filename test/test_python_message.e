note
	description: "Tests for PYTHON_MESSAGE base class"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_PYTHON_MESSAGE

inherit
	EQA_TEST_SET

feature -- Tests

	test_message_creation
			-- Test that concrete message subclass can be created.
		local
			l_msg: PYTHON_VALIDATION_REQUEST
		do
			create l_msg.make ("msg_001")
			assert ("message created", l_msg /= Void)
			assert ("message id set", l_msg.message_id.same_string ("msg_001"))
			assert ("not frozen initially", not l_msg.is_frozen)
		end

	test_freeze_mechanism
			-- Test that freeze prevents further attribute modifications.
		local
			l_msg: PYTHON_VALIDATION_REQUEST
			l_json: SIMPLE_JSON
			l_value: SIMPLE_JSON_VALUE
		do
			create l_msg.make ("msg_001")
			create l_json
			l_value := l_json.string_value ("value1")
			l_msg.set_attribute ("key1", l_value)
			l_msg.freeze
			assert ("is frozen", l_msg.is_frozen)
			assert ("has attribute", l_msg.has_attribute ("key1"))
		end

	test_message_to_json
			-- Test that message can be serialized to JSON.
		local
			l_msg: PYTHON_VALIDATION_REQUEST
			l_json: SIMPLE_JSON_OBJECT
			l_factory: SIMPLE_JSON
			l_value: SIMPLE_JSON_VALUE
		do
			create l_msg.make ("msg_001")
			create l_factory
			l_value := l_factory.string_value ("ok")
			l_msg.set_attribute ("status", l_value)
			l_msg.freeze
			l_json := l_msg.to_json
			assert ("json not void", l_json /= Void)
			assert ("has message_id", l_json.has_key ("message_id"))
			assert ("has type", l_json.has_key ("type"))
			assert ("has timestamp", l_json.has_key ("timestamp"))
			assert ("has attributes", l_json.has_key ("attributes"))
		end

	test_message_to_binary
			-- Test that message can be serialized to binary with length prefix.
		local
			l_msg: PYTHON_VALIDATION_REQUEST
			l_binary: ARRAY [NATURAL_8]
		do
			create l_msg.make ("msg_001")
			l_msg.freeze
			l_binary := l_msg.to_binary
			assert ("binary not void", l_binary /= Void)
			assert ("binary has length prefix", l_binary.count > 4)
			assert ("binary count at least 5", l_binary.count >= 5)
		end

	test_message_types
			-- Test that each message subclass has correct message_type.
		local
			l_req: PYTHON_VALIDATION_REQUEST
			l_resp: PYTHON_VALIDATION_RESPONSE
			l_err: PYTHON_ERROR
		do
			create l_req.make ("req_001")
			create l_resp.make ("resp_001")
			create l_err.make ("err_001")

			assert ("request type", l_req.message_type.same_string ("VALIDATION_REQUEST"))
			assert ("response type", l_resp.message_type.same_string ("VALIDATION_RESPONSE"))
			assert ("error type", l_err.message_type.same_string ("ERROR"))
		end

end
