note
	description: "[
		Concrete message class for validation requests sent to Eiffel validator.

		Used by Python clients to request validation of manufacturing data
		(PCB layouts, component placement, signal integrity, etc.).
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class PYTHON_VALIDATION_REQUEST

inherit
	PYTHON_MESSAGE

create
	make

feature -- Access

	message_type: STRING_32
			-- Type of message is VALIDATION_REQUEST.
		do
			Result := {STRING_32} "VALIDATION_REQUEST"
		end

invariant
	correct_type: message_type.same_string ({STRING_32} "VALIDATION_REQUEST")

end
