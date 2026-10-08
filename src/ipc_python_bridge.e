note
	description: "[
		IPC bridge for Eiffel-Python communication on the same machine.

		Transport: TCP on loopback (127.0.0.1, default port 9001) with
		4-byte big-endian length-prefixed UTF-8 JSON frames, as spoken by
		python_ipc_server.py. See PYTHON_TCP_BRIDGE for the wire format.

		Named pipes: the class was first sketched for Windows named pipes,
		hence `make_with_pipe_name' and `pipe_name' (and the old notes in
		TRANSPORT_STATUS.md). The Python server that exists listens on TCP,
		not on a pipe, so this bridge speaks TCP. `make_with_pipe_name' is
		kept for compatibility: it records the name as a label and connects
		to 127.0.0.1:9001. No named pipe is opened.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

class
	IPC_PYTHON_BRIDGE

inherit
	PYTHON_TCP_BRIDGE

create
	make_with_pipe_name,
	make_with_port

feature {NONE} -- Initialization

	make_with_pipe_name (a_pipe_name: STRING_32)
			-- IPC bridge labelled `a_pipe_name', for the server on 127.0.0.1:`Default_port'.
		require
			pipe_name_not_empty: a_pipe_name /= Void and then a_pipe_name.count > 0
		do
			pipe_name := a_pipe_name
			make_tcp (Loopback, Default_port, Default_timeout_ms)
		ensure
			pipe_set: pipe_name.same_string (a_pipe_name)
			port_default: port = Default_port
			not_initialized: not is_initialized
			not_connected: not is_connected
		end

	make_with_port (a_port: INTEGER)
			-- IPC bridge for the server on 127.0.0.1:`a_port'.
		require
			port_valid: a_port > 0 and a_port < 65536
		do
			pipe_name := {STRING_32} "tcp:127.0.0.1:" + a_port.out
			make_tcp (Loopback, a_port, Default_timeout_ms)
		ensure
			port_set: port = a_port
			not_initialized: not is_initialized
			not_connected: not is_connected
		end

feature -- Access

	pipe_name: STRING_32
			-- Label given at creation (no named pipe is used; see class notes).

	transport_name: STRING = "IPC"
			-- <Precursor>

feature -- Constants

	Loopback: STRING = "127.0.0.1"
			-- IPC is same-machine only.

	Default_port: INTEGER = 9001
			-- Port python_ipc_server.py listens on by default.

	Default_timeout_ms: INTEGER = 5000
			-- Default I/O timeout.

invariant
	pipe_name_not_empty: pipe_name /= Void and then pipe_name.count > 0
	loopback_only: host.same_string_general (Loopback)

end
