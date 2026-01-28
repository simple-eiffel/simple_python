note
	description: "Tests for SIMPLE_PYTHON facade library"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_SIMPLE_PYTHON

inherit
	EQA_TEST_SET

feature -- Tests

	test_http_bridge_creation
			-- Test that new_http_bridge creates unconfigured HTTP bridge.
		local
			l_library: SIMPLE_PYTHON
			l_bridge: HTTP_PYTHON_BRIDGE
		do
			create l_library.make
			l_bridge := l_library.new_http_bridge ("127.0.0.1", 8080)
			assert ("bridge_not_void", l_bridge /= Void)
			assert ("host_set", l_bridge.host.same_string ("127.0.0.1"))
			assert ("port_set", l_bridge.port = 8080)
			assert ("not_initialized", not l_bridge.is_initialized)
		end

	test_ipc_bridge_creation
			-- Test that new_ipc_bridge creates unconfigured IPC bridge.
		local
			l_library: SIMPLE_PYTHON
			l_bridge: IPC_PYTHON_BRIDGE
		do
			create l_library.make
			l_bridge := l_library.new_ipc_bridge ("\\.\\pipe\\test_eiffel")
			assert ("bridge created", l_bridge /= Void)
			assert ("pipe name set", l_bridge.pipe_name.same_string ("\\.\\pipe\\test_eiffel"))
			assert ("not initialized", not l_bridge.is_initialized)
		end

	test_grpc_bridge_creation
			-- Test that new_grpc_bridge creates unconfigured gRPC bridge (Phase 2).
		local
			l_library: SIMPLE_PYTHON
			l_bridge: GRPC_PYTHON_BRIDGE
		do
			create l_library.make
			l_bridge := l_library.new_grpc_bridge ("0.0.0.0", 50051)
			assert ("bridge created", l_bridge /= Void)
			assert ("host set", l_bridge.host.same_string ("0.0.0.0"))
			assert ("port set", l_bridge.port = 50051)
			assert ("not initialized", not l_bridge.is_initialized)
		end

end
