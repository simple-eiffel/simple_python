note
	description: "Shared checks for the bridge integration tests."
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

deferred class
	PYTHON_BRIDGE_TEST_SUPPORT

inherit
	TEST_SET_BASE

feature {NONE} -- Checks

	assert_round_trip (a_bridge: PYTHON_TCP_BRIDGE; a_id: STRING_32)
			-- Send a request with id `a_id' and check the reply answers it.
		local
			l_message: PYTHON_VALIDATION_REQUEST
			l_sent: BOOLEAN
		do
			create l_message.make (a_id)
			l_sent := a_bridge.send_message (l_message)
			assert ({STRING_32} "sent " + a_id + {STRING_32} ": " + a_bridge.last_error_message, l_sent)
			refute ("no error", a_bridge.has_error)
			if attached a_bridge.receive_message as al_reply then
				assert ({STRING_32} "reply id matches " + a_id, al_reply.message_id.same_string (a_id))
				assert ("reply type", al_reply.message_type.same_string ({STRING_32} "VALIDATION_RESPONSE"))
				assert ("reply result PASS", attached al_reply.get_attribute ({STRING_32} "result") as al_r
					and then al_r.is_string and then al_r.as_string_32.same_string ({STRING_32} "PASS"))
			else
				assert ("reply received", False)
			end
		end

end
