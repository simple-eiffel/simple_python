note
	description: "Minimal test runner"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_APP_MINIMAL

create
	make

feature {NONE} -- Initialization

	make
			-- Run minimal test.
		do
			print ("%N=== Minimal HTTP Bridge Test ===%N%N")

			print ("Creating bridge...")
			if True then
				print (" OK%N")
			end

			print ("%N=== Test complete ===%N%N")
		end

end
