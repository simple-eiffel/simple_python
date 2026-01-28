note
	description: "[
		Deferred interface for all Eiffel-Python bridge implementations.

		Defines the contract that all bridge types (HTTP, IPC, gRPC) must satisfy.
		Bridges are transport-agnostic; they differ only in how messages are sent/received.

		Design by Contract Approach:
		- Preconditions enforce valid input state
		- Postconditions guarantee state changes after operations
		- Invariants ensure consistency throughout bridge lifecycle
		- Frame conditions (MML |=|) specify what collections did NOT change
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

deferred class
	PYTHON_BRIDGE

feature -- Status Queries

	is_initialized: BOOLEAN
			-- Is bridge initialized and ready for communication?
		deferred
		end

	is_connected: BOOLEAN
			-- Is bridge currently connected (for HTTP: server listening, for IPC: pipe open)?
		deferred
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		deferred
		end

	last_error_message: detachable STRING_32
			-- Human-readable error message from last failed operation.
		deferred
		end

feature -- Bridge Lifecycle

	initialize: BOOLEAN
			-- Initialize bridge (start HTTP server or open IPC pipe).
			-- Returns true if successful, false if initialization failed.
		require
			not_initialized: not is_initialized
		deferred
		ensure
			initialized_on_success: Result implies is_initialized
			not_initialized_on_failure: (not Result) implies (not is_initialized)
			error_set_on_failure: (not Result) implies has_error
		end

	close
			-- Close bridge and clean up resources.
			-- Safe to call multiple times.
		require
			not_void: True
		deferred
		ensure
			not_connected: not is_connected
		end

feature -- Message Operations

	send_message (a_message: PYTHON_MESSAGE): BOOLEAN
			-- Send message through bridge.
			-- Returns true if message was successfully sent.
		require
			initialized: is_initialized
			message_not_void: a_message /= Void
		deferred
		ensure
			success_or_error_set: Result implies True  -- Success: message sent
			failure_implies_error: (not Result) implies has_error  -- Failure: error set
		end

	receive_message: detachable PYTHON_MESSAGE
			-- Receive next message from bridge (blocking).
			-- Returns Void if timeout or error.
		require
			initialized: is_initialized
		deferred
		end

feature -- Configuration

	set_timeout (a_timeout_ms: INTEGER)
			-- Set receive timeout in milliseconds.
		require
			timeout_positive: a_timeout_ms > 0
			timeout_reasonable: a_timeout_ms <= 3600000  -- Max 1 hour
		deferred
		end

invariant
	-- Consistent state: error implies failure, not error implies potential success
	error_implies_not_connected: has_error implies (not is_connected)

end
