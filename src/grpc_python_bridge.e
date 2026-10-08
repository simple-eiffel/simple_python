note
	description: "[
		"gRPC" bridge for Eiffel-Python communication.

		Transport: TCP to `host':`port' (python_grpc_server.py listens on
		127.0.0.1:9002) with 4-byte big-endian length-prefixed UTF-8 JSON
		frames. See PYTHON_TCP_BRIDGE for the wire format. Despite the name,
		this is not HTTP/2 or protobuf gRPC: it speaks the framing the
		Python server actually implements, over one persistent connection.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

class GRPC_PYTHON_BRIDGE

inherit
	PYTHON_TCP_BRIDGE

create
	make_with_host_port

feature {NONE} -- Initialization

	make_with_host_port (a_host: STRING_32; a_port: INTEGER)
			-- gRPC bridge for the server at `a_host':`a_port'.
		require
			host_not_empty: a_host /= Void and then a_host.count > 0
			port_valid: a_port > 0 and a_port < 65536
		do
			make_tcp (a_host, a_port, Default_timeout_ms)
		ensure
			host_set: host.same_string (a_host)
			port_set: port = a_port
			not_initialized: not is_initialized
			not_connected: not is_connected
		end

feature -- Access

	transport_name: STRING = "gRPC"
			-- <Precursor>

feature -- Constants

	Default_port: INTEGER = 9002
			-- Port python_grpc_server.py listens on by default.

	Default_timeout_ms: INTEGER = 5000
			-- Default I/O timeout.

end
