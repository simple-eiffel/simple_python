note
	description: "Simple test runner for HTTP_PYTHON_BRIDGE"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_APP_SIMPLE

create
	make

feature {NONE} -- Initialization

	make
			-- Run HTTP bridge tests.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
			l_msg: PYTHON_VALIDATION_REQUEST
			l_factory: SIMPLE_JSON
		do
			print ("%N=== simple_python HTTP Bridge Tests ===%N%N")

			-- Test 1: Create bridge
			print ("Test 1: Create HTTP bridge...")
			create l_bridge.make_with_host_port ("localhost", 8080)
			if l_bridge.host.same_string ("localhost") and l_bridge.port = 8080 then
				print (" OK%N")
			else
				print (" FAIL%N")
			end

			-- Test 2: Initialize bridge
			print ("Test 2: Initialize bridge...")
			if l_bridge.initialize then
				print (" OK%N")
			else
				print (" FAIL%N")
			end

			-- Test 3: Create and freeze a validation request
			print ("Test 3: Create validation request...")
			create l_msg.make ("test_001")
			create l_factory
			l_msg.set_attribute ("board_id", l_factory.string_value ("PCB-001"))
			l_msg.set_attribute ("temperature", l_factory.integer_value (45))
			l_msg.freeze
			if l_msg.is_frozen then
				print (" OK%N")
			else
				print (" FAIL%N")
			end

			-- Test 4: Serialize to JSON
			print ("Test 4: Serialize to JSON...")
			if attached l_msg.to_json as l_json then
				if l_json.has_key ("message_id") and l_json.has_key ("type") then
					print (" OK%N")
				else
					print (" FAIL%N")
				end
			else
				print (" FAIL%N")
			end

			-- Test 5: Skip actual send (requires Python server)
			print ("Test 5: Skip send_message test (requires Python server)...")
			print (" SKIPPED%N")

			-- Test 6: Close bridge
			print ("Test 6: Close bridge...")
			l_bridge.close
			if not l_bridge.is_connected then
				print (" OK%N")
			else
				print (" FAIL%N")
			end

			print ("%N=== Tests complete ===%N%N")
		end

end
