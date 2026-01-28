note
	description: "[
		Concrete message class for error messages in Eiffel-Python communication.

		Sent when a request cannot be processed (invalid input, timeout, server error).
		Includes error code and human-readable description.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class PYTHON_ERROR

inherit
	PYTHON_MESSAGE

create
	make

feature -- Access

	message_type: STRING_32
			-- Type of message is ERROR.
		do
			Result := {STRING_32} "ERROR"
		end

invariant
	correct_type: message_type.same_string ({STRING_32} "ERROR")

end
