note
	description: "Tests for HTTP_PYTHON_BRIDGE"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_HTTP_PYTHON_BRIDGE

inherit
	EQA_TEST_SET

feature -- Tests

	test_make_creates_unconfigured_bridge
			-- Test that make_with_host_port creates unconfigured bridge.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
		do
			create l_bridge.make_with_host_port ("localhost", 8080)
			assert ("host set", l_bridge.host.same_string ("localhost"))
			assert ("port set", l_bridge.port = 8080)
			assert ("timeout default", l_bridge.timeout_ms = 30000)
			assert ("not initialized", not l_bridge.is_initialized)
			assert ("no error", not l_bridge.has_error)
		end

	test_set_timeout_updates_timeout
			-- Test that set_timeout updates timeout value.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
		do
			create l_bridge.make_with_host_port ("localhost", 8080)
			l_bridge.set_timeout (5000)
			assert ("timeout updated", l_bridge.timeout_ms = 5000)
		end

	test_initialize_succeeds
			-- Test that initialize sets is_initialized and is_connected.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
			l_result: BOOLEAN
		do
			create l_bridge.make_with_host_port ("localhost", 8080)
			l_result := l_bridge.initialize
			assert ("initialize returns true", l_result)
			assert ("is initialized", l_bridge.is_initialized)
			assert ("is connected", l_bridge.is_connected)
			assert ("no error", not l_bridge.has_error)
		end

	test_close_disconnects_bridge
			-- Test that close sets is_connected to False.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
		do
			create l_bridge.make_with_host_port ("localhost", 8080)
			l_bridge.close
			assert ("not connected", not l_bridge.is_connected)
		end

	test_active_connections_query
			-- Test that active_connections returns integer.
		local
			l_bridge: HTTP_PYTHON_BRIDGE
		do
			create l_bridge.make_with_host_port ("localhost", 8080)
			assert ("connections_zero", l_bridge.active_connections = 0)
		end

end
