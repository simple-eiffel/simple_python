note
	description: "[
		A Python test server started through one of the blocking launcher scripts
		(start_*_server_blocking.py). The launcher prints "READY <pid>" once the
		server it started is listening; `stop' ends that process tree and no other.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

class
	PYTHON_TEST_SERVER

create
	make

feature {NONE} -- Initialization

	make (a_launcher: READABLE_STRING_GENERAL; a_port: INTEGER)
			-- Server started by launcher script `a_launcher' on `a_port'.
		require
			launcher_not_empty: not a_launcher.is_empty
			port_valid: a_port > 0 and a_port < 65536
		do
			create launcher.make_from_string_general (a_launcher)
			port := a_port
			create last_launch_output.make_empty
		ensure
			launcher_set: launcher.same_string_general (a_launcher)
			port_set: port = a_port
			not_running: not is_running
		end

feature -- Access

	launcher: STRING_32
			-- Launcher script, relative to the working directory.

	port: INTEGER
			-- Port the server listens on.

	pid: INTEGER
			-- Process id of the server this object started; 0 when none.

	last_launch_output: STRING_32
			-- What the launcher printed on its last `start'.

feature -- Status report

	is_running: BOOLEAN
			-- Did `start' launch a server that `stop' has not yet ended?
		do
			Result := pid > 0
		end

feature -- Basic operations

	start
			-- Run the launcher and record the process id of the server it started.
			-- `is_running' stays False when the launcher fails (for example, port busy).
		require
			not_running: not is_running
		local
			l_proc: SIMPLE_PROCESS
		do
			create l_proc.make
			l_proc.execute ({STRING_32} "python3 ./" + launcher + " " + port.out)
			if attached l_proc.last_output as al_output then
				last_launch_output := al_output.twin
				pid := ready_pid (al_output)
			else
				create last_launch_output.make_empty
			end
		end

	stop
			-- End the process tree this object started; never any other process.
		local
			l_proc: SIMPLE_PROCESS
		do
			if is_running then
				create l_proc.make
				if {PLATFORM}.is_windows then
					l_proc.execute ({STRING_32} "taskkill /F /T /PID " + pid.out)
				else
					l_proc.execute ({STRING_32} "kill " + pid.out)
				end
				pid := 0
			end
		ensure
			stopped: not is_running
		end

feature {NONE} -- Implementation

	ready_pid (a_output: READABLE_STRING_32): INTEGER
			-- Process id from the launcher's "READY <pid>" line, or 0 when there is none.
		local
			l_line, l_number: STRING_32
		do
			across a_output.split ('%N') as ic loop
				create l_line.make_from_string (ic)
				l_line.adjust
				if l_line.starts_with ({STRING_32} "READY ") then
					l_number := l_line.substring (7, l_line.count)
					if l_number.is_integer and then l_number.to_integer > 0 then
						Result := l_number.to_integer
					end
				end
			end
		ensure
			non_negative: Result >= 0
		end

end
