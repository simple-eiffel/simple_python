note
	description: "[
		Concrete message class for validation responses from Eiffel validator.

		Contains validation results, defect list, recommendations, and
		performance metrics from the validation analysis.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class PYTHON_VALIDATION_RESPONSE

inherit
	PYTHON_MESSAGE

create
	make

feature -- Access

	message_type: STRING_32
			-- Type of message is VALIDATION_RESPONSE.
		do
			Result := {STRING_32} "VALIDATION_RESPONSE"
		end

invariant
	correct_type: message_type.same_string ({STRING_32} "VALIDATION_RESPONSE")

end
