note
	description: "[
		Library facade for simple_python Eiffel-Python bridge creation and coordination.

		Provides factory methods for creating HTTP, IPC, and gRPC bridges to enable
		communication between Eiffel validators and Python orchestration systems.

		Usage:
			local
				l_bridge: HTTP_PYTHON_BRIDGE
				l_request: PYTHON_VALIDATION_REQUEST
				l_response: PYTHON_VALIDATION_RESPONSE
			do
				-- Create HTTP bridge on localhost:8080
				l_bridge := create {SIMPLE_PYTHON}.make.new_http_bridge ("localhost", 8080)

				-- Create validation request
				create l_request.make ("PCB_001")

				-- Initialize bridge and send request
				if l_bridge.initialize then
					if l_bridge.send_message (l_request) then
						l_response := l_bridge.receive_message
						-- Process response...
					end
					l_bridge.close
				end
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class
	SIMPLE_PYTHON

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize library state.
			-- Library is ready to create bridges on demand.
		do
			-- No-op: Bridges are created on demand via factory methods
		ensure
			-- Library state ready for bridge creation
		end

feature -- HTTP Bridge Creation

	new_http_bridge (a_host: STRING_32; a_port: INTEGER): HTTP_PYTHON_BRIDGE
			-- Create a new HTTP REST API bridge.
			--
			-- Parameters:
			--   a_host: Hostname or IP address (e.g., "localhost", "0.0.0.0")
			--   a_port: TCP port number (e.g., 8080)
			--
			-- Returns: Unconfigured bridge (call initialize to start server)
		require
			host_not_void: a_host /= Void and then a_host.count > 0
			port_valid: a_port > 0 and a_port < 65536
		do
			create Result.make_with_host_port (a_host, a_port)
		ensure
			result_not_void: Result /= Void
			host_set: Result.host.same_string (a_host)
			port_set: Result.port = a_port
			not_initialized: not Result.is_initialized
		end

feature -- IPC Bridge Creation

	new_ipc_bridge (a_pipe_name: STRING_32): IPC_PYTHON_BRIDGE
			-- Create a new Windows named pipes IPC bridge.
			--
			-- Parameters:
			--   a_pipe_name: Named pipe name (e.g., "\\.\pipe\eiffel_validator")
			--
			-- Returns: Unconfigured bridge
		require
			pipe_name_not_void: a_pipe_name /= Void and then a_pipe_name.count > 0
		do
			create Result.make_with_pipe_name (a_pipe_name)
		ensure
			result_not_void: Result /= Void
			pipe_set: Result.pipe_name.same_string (a_pipe_name)
			not_initialized: not Result.is_initialized
		end

feature -- gRPC Bridge Creation (Phase 2)

	new_grpc_bridge (a_host: STRING_32; a_port: INTEGER): GRPC_PYTHON_BRIDGE
			-- Create a new gRPC RPC bridge.
			--
			-- Parameters:
			--   a_host: Bind address (e.g., "0.0.0.0")
			--   a_port: TCP port (e.g., 50051)
			--
			-- Returns: Unconfigured bridge
		require
			host_not_void: a_host /= Void and then a_host.count > 0
			port_valid: a_port > 0 and a_port < 65536
		do
			create Result.make_with_host_port (a_host, a_port)
		ensure
			result_not_void: Result /= Void
			host_set: Result.host.same_string (a_host)
			port_set: Result.port = a_port
			not_initialized: not Result.is_initialized
		end

invariant
	-- Library has no state; all state is in bridge instances
end
