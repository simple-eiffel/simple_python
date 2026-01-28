# SPECIFICATION: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Specification Phase:** Step 7 - Complete Formal Specification

---

## Overview

This document synthesizes all prior specification steps into complete formal class specifications with full Eiffel code, contracts, and implementation guidance.

---

## Class: SIMPLE_PYTHON (Library Facade)

```eiffel
note
    description: "Library facade for simple_python bridge creation and coordination."
    author: "Simple Eiffel Contributors"
    license: "MIT"

class
    SIMPLE_PYTHON

create
    make

feature {NONE} -- Initialization

    make
            -- Initialize library state.
        do
            -- No-op: Create new HTTP/IPC/gRPC bridges on demand
        ensure
            -- Library is ready to create bridges
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
            host_set: Result.host = a_host
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
            pipe_set: Result.pipe_name = a_pipe_name
            not_initialized: not Result.is_initialized
        end

feature -- gRPC Bridge Creation

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
            host_set: Result.host = a_host
            port_set: Result.port = a_port
            not_initialized: not Result.is_initialized
        end

end
```

---

## Deferred Class: PYTHON_BRIDGE (Bridge Interface)

```eiffel
note
    description: "Abstract interface for protocol-agnostic Python bridge communication."
    author: "Simple Eiffel Contributors"
    design: "Protocol-independent contract; HTTP/IPC/gRPC provide implementations"

deferred class
    PYTHON_BRIDGE

create
    -- Deferred: subclasses define creation

feature -- Initialization

    initialize
            -- Initialize bridge (start server, open connection).
            --
            -- For HTTP: Starts simple_web HTTP server, registers endpoints.
            -- For IPC: Creates named pipe server, waits for client connection.
            -- For gRPC: Starts gRPC service, binds socket I/O.
        require
            not_already_initialized: not is_initialized
        deferred
        ensure
            is_initialized: is_initialized
            not_connected_yet: not is_connected
        end

feature -- Communication

    send_message (a_request: PYTHON_REQUEST)
            -- Send request to Python.
            --
            -- Protocol-specific behavior:
            -- - HTTP: JSON POST to /api/validate
            -- - IPC: Length-prefix binary frame to named pipe
            -- - gRPC: Protocol Buffers RPC call
        require
            bridge_initialized: is_initialized
            request_not_void: a_request /= Void
            request_valid: a_request.is_valid
        deferred
        ensure
            message_sent: is_connected or last_error /= Void
            timestamp_recorded: last_message_timestamp > old last_message_timestamp
        end

    receive_response: PYTHON_RESPONSE
            -- Receive response from Python.
            --
            -- Blocks until response available (respects timeout).
            -- Throws on timeout or protocol error.
        require
            bridge_initialized: is_initialized
        deferred
        ensure
            response_not_void: Result /= Void
            response_valid: Result.is_valid or Result.error_count > 0
            timestamp_recorded: Result.timestamp > 0
        end

feature -- Status Queries

    is_initialized: BOOLEAN
            -- Is bridge initialized and ready?
        deferred
        end

    is_connected: BOOLEAN
            -- Is connection to Python currently active?
        deferred
        end

    last_error: detachable STRING_32
            -- Last error encountered (Void if no error).
        deferred
        end

    last_message_timestamp: INTEGER_64
            -- Unix timestamp (microseconds) of last sent message.
        deferred
        ensure
            non_negative: Result >= 0
        end

    last_response_timestamp: INTEGER_64
            -- Unix timestamp (microseconds) of last received response.
        deferred
        ensure
            non_negative: Result >= 0
        end

feature -- Cleanup

    shutdown
            -- Close bridge, release resources.
            --
            -- Safe to call even in error state.
        deferred
        ensure
            not_connected: not is_connected
        end

invariant
    timestamps_monotonic: last_message_timestamp <= last_response_timestamp or last_response_timestamp = 0

end
```

---

## Deferred Class: PYTHON_MESSAGE (Message Interface)

```eiffel
note
    description: "Abstract message interface for protocol-agnostic communication."
    author: "Simple Eiffel Contributors"
    design: "Shared by HTTP (JSON), IPC (binary), gRPC (protobuf) via inheritance"

deferred class
    PYTHON_MESSAGE

create
    -- Deferred: REQUEST/RESPONSE/ERROR provide creation

feature -- Access

    message_id: STRING_32
            -- Unique message identifier (UUID format).
        deferred
        ensure
            non_void: Result /= Void
            not_empty: Result.count > 0
            valid_uuid: Result.count = 36  -- "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        end

    message_type: STRING_32
            -- Type of message ("validate_request", "validate_response", "error_response").
        deferred
        ensure
            non_void: Result /= Void
            valid: Result = "validate_request" or Result = "validate_response" or Result = "error_response"
        end

    payload: detachable STRING_32
            -- Message payload (protocol-specific encoding).
        deferred
        end

    timestamp: INTEGER_64
            -- Unix timestamp (microseconds since epoch).
        deferred
        ensure
            positive: Result > 0
        end

    compliance_metadata: detachable MANUFACTURING_METADATA
            -- Optional manufacturing audit trail.
        deferred
        end

feature -- Serialization

    to_bytes: ARRAY [NATURAL_8]
            -- Serialize message to protocol-specific bytes.
            --
            -- HTTP: JSON string → UTF-8 bytes
            -- IPC: Binary structure → bytes
            -- gRPC: Protocol Buffers → bytes
        require
            is_valid: is_valid
        deferred
        ensure
            result_not_void: Result /= Void
            result_not_empty: Result.count > 0
        end

    from_bytes (a_bytes: ARRAY [NATURAL_8])
            -- Deserialize message from protocol-specific bytes.
        require
            bytes_not_void: a_bytes /= Void
            bytes_not_empty: a_bytes.count > 0
        deferred
        ensure
            message_id_set: message_id /= Void and then message_id.count > 0
            message_type_set: message_type /= Void
            timestamp_set: timestamp > 0
        end

feature -- Validation

    is_valid: BOOLEAN
            -- Is message well-formed?
        deferred
        ensure
            has_required_fields: Result implies (
                message_id /= Void and then
                message_type /= Void and then
                timestamp > 0
            )
        end

invariant
    fields_non_void_when_valid: is_valid implies (
        message_id /= Void and
        message_type /= Void
    )
    timestamp_positive: timestamp >= 0

end
```

---

## Concrete Class: PYTHON_REQUEST (Request Message)

```eiffel
note
    description: "Request message: design to validate + rules to apply."
    author: "Simple Eiffel Contributors"

class
    PYTHON_REQUEST

inherit
    PYTHON_MESSAGE

create
    make,
    make_default

feature -- Creation

    make (a_design_data: STRING_32)
            -- Create request with design data.
        require
            data_not_void: a_design_data /= Void
            data_not_empty: a_design_data.count > 0
        do
            design_data := a_design_data
            priority := 5  -- Default: medium priority
            create validation_rules.make (0)
            generate_message_id
            timestamp := current_time_microseconds
            message_type := "validate_request"
        ensure
            design_set: design_data = a_design_data
            message_id_generated: message_id /= Void
            is_valid: is_valid
        end

    make_default
            -- Create request with empty data (for testing).
        do
            design_data := ""
            priority := 5
            create validation_rules.make (0)
            generate_message_id
            timestamp := current_time_microseconds
            message_type := "validate_request"
        end

feature -- Access

    design_data: STRING_32
            -- Design/code to validate.
        attribute
        end

    validation_rules: ARRAY [STRING_32]
            -- Rules to apply.
        attribute
        end

    priority: INTEGER
            -- Priority (1=high, 10=low).
        attribute
        end

    correlation_id: STRING_32
            -- Linked request ID.
        attribute
        end

feature -- Configuration

    set_rules (a_rules: ARRAY [STRING_32]): like Current
            -- Set validation rules.
        require
            rules_not_void: a_rules /= Void
        do
            validation_rules := a_rules
            Result := Current
        ensure
            rules_set: validation_rules = a_rules
        end

    set_priority (a_priority: INTEGER): like Current
            -- Set request priority.
        require
            valid: a_priority >= 1 and a_priority <= 10
        do
            priority := a_priority
            Result := Current
        ensure
            priority_set: priority = a_priority
        end

feature -- Implementation (from PYTHON_MESSAGE)

    is_valid: BOOLEAN
        do
            Result := design_data /= Void and then design_data.count > 0 and then
                      validation_rules /= Void and then
                      priority >= 1 and priority <= 10 and then
                      message_id /= Void and then
                      message_type = "validate_request"
        end

    to_bytes: ARRAY [NATURAL_8]
        do
            -- Protocol-specific serialization
            -- HTTP: JSON via simple_json
            -- IPC: Binary via serializer
            -- gRPC: Protocol Buffers
        end

    from_bytes (a_bytes: ARRAY [NATURAL_8])
        do
            -- Protocol-specific deserialization
        end

invariant
    design_non_void: design_data /= Void
    rules_non_void: validation_rules /= Void
    priority_valid: priority >= 1 and priority <= 10

end
```

---

## Concrete Class: PYTHON_RESPONSE (Response Message)

```eiffel
note
    description: "Response message: validation results (valid/invalid + errors/warnings)."
    author: "Simple Eiffel Contributors"

class
    PYTHON_RESPONSE

inherit
    PYTHON_MESSAGE

create
    make_valid,
    make_with_errors,
    make_with_warning

feature -- Creation

    make_valid
            -- Create valid response (no errors).
        do
            is_valid := True
            create errors.make (0)
            create warnings.make (0)
            validation_duration_ms := 0
            generate_message_id
            timestamp := current_time_microseconds
            message_type := "validate_response"
        ensure
            is_valid: is_valid
            no_errors: errors.count = 0
        end

    make_with_errors (a_errors: ARRAY [STRING_32])
            -- Create invalid response with errors.
        require
            errors_not_void: a_errors /= Void
            errors_not_empty: a_errors.count > 0
        do
            is_valid := False
            errors := a_errors
            create warnings.make (0)
            validation_duration_ms := 0
            generate_message_id
            timestamp := current_time_microseconds
            message_type := "validate_response"
        ensure
            not_valid: not is_valid
            errors_set: errors = a_errors
        end

feature -- Access

    is_valid: BOOLEAN
            -- Did validation pass?
        attribute
        end

    errors: ARRAY [STRING_32]
            -- Validation failures.
        attribute
        end

    warnings: ARRAY [STRING_32]
            -- Non-critical issues.
        attribute
        end

    evidence_url: detachable STRING_32
            -- URL to evidence artifact.
        attribute
        end

    validation_duration_ms: INTEGER
            -- How long validation took.
        attribute
        end

feature -- Implementation (from PYTHON_MESSAGE)

    to_bytes: ARRAY [NATURAL_8]
        do
            -- JSON/binary/protobuf serialization
        end

    from_bytes (a_bytes: ARRAY [NATURAL_8])
        do
            -- JSON/binary/protobuf deserialization
        end

invariant
    valid_xor_errors: is_valid xor (errors.count > 0)
    errors_non_void: errors /= Void
    warnings_non_void: warnings /= Void

end
```

---

## Concrete Class: HTTP_PYTHON_BRIDGE

```eiffel
note
    description: "HTTP REST API bridge implementation."
    author: "Simple Eiffel Contributors"
    dependencies: "simple_http, simple_web, simple_json"

class
    HTTP_PYTHON_BRIDGE

inherit
    PYTHON_BRIDGE

create
    make_with_host_port

feature {NONE} -- Initialization

    make_with_host_port (a_host: STRING_32; a_port: INTEGER)
            -- Create unconfigured HTTP bridge.
        require
            host_not_void: a_host /= Void
            port_valid: a_port > 0 and a_port < 65536
        do
            host := a_host
            port := a_port
            timeout_ms := 5000
            max_retries := 3
            max_message_size := 10_000_000
            is_initialized := False
            is_connected := False
        ensure
            host_set: host = a_host
            port_set: port = a_port
        end

feature -- Access

    host: STRING_32
            -- Hostname or IP address.
        attribute
        end

    port: INTEGER
            -- TCP port.
        attribute
        end

    timeout_ms: INTEGER
            -- Request timeout (milliseconds).
        attribute
        end

    max_retries: INTEGER
            -- Max retry attempts.
        attribute
        end

    max_message_size: INTEGER
            -- Max message size (bytes).
        attribute
        end

feature -- Configuration

    set_timeout (a_ms: INTEGER): like Current
        require
            positive: a_ms > 0
        do
            timeout_ms := a_ms
            Result := Current
        ensure
            set: timeout_ms = a_ms
        end

    set_max_retries (a_count: INTEGER): like Current
        require
            non_negative: a_count >= 0
        do
            max_retries := a_count
            Result := Current
        ensure
            set: max_retries = a_count
        end

feature -- Implementation (from PYTHON_BRIDGE)

    initialize
        do
            -- Create simple_web server
            -- Register /api/validate endpoint
            -- Listen on host:port
            is_initialized := True
        ensure
            is_initialized: is_initialized
        end

    send_message (a_request: PYTHON_REQUEST)
        require
            bridge_initialized: is_initialized
            request_not_void: a_request /= Void
            request_valid: a_request.is_valid
        do
            -- Serialize request to JSON
            -- HTTP POST to /api/validate
            -- Handle retries on transient errors
            is_connected := True
            last_message_timestamp := current_time_microseconds
        ensure
            message_sent: is_connected or last_error /= Void
        end

    receive_response: PYTHON_RESPONSE
        require
            bridge_initialized: is_initialized
        do
            -- Wait for HTTP response (with timeout_ms)
            -- Deserialize JSON to PYTHON_RESPONSE
            last_response_timestamp := current_time_microseconds
            create Result.make_valid
        ensure
            result_not_void: Result /= Void
        end

    shutdown
        do
            -- Close HTTP server
            -- Release connections
            is_connected := False
        ensure
            not_connected: not is_connected
        end

feature -- Status Queries

    is_initialized: BOOLEAN
        attribute
        end

    is_connected: BOOLEAN
        attribute
        end

    last_error: detachable STRING_32
        attribute
        end

    last_message_timestamp: INTEGER_64
        attribute
        end

    last_response_timestamp: INTEGER_64
        attribute
        end

invariant
    timeout_positive: timeout_ms > 0
    max_retries_non_negative: max_retries >= 0

end
```

---

## Concrete Class: IPC_PYTHON_BRIDGE

```eiffel
note
    description: "Windows named pipes IPC bridge implementation."
    author: "Simple Eiffel Contributors"
    dependencies: "simple_ipc"
    platform: "Windows only (Phase 2: Unix domain sockets)"

class
    IPC_PYTHON_BRIDGE

inherit
    PYTHON_BRIDGE

create
    make_with_pipe_name

feature {NONE} -- Initialization

    make_with_pipe_name (a_pipe_name: STRING_32)
            -- Create unconfigured IPC bridge.
        require
            pipe_name_not_void: a_pipe_name /= Void
            pipe_name_not_empty: a_pipe_name.count > 0
        do
            pipe_name := a_pipe_name
            max_message_size := 1_000_000  -- 1 MB default
            is_initialized := False
            is_connected := False
        ensure
            pipe_set: pipe_name = a_pipe_name
        end

feature -- Access

    pipe_name: STRING_32
            -- Named pipe name (e.g., "\\.\pipe\eiffel_validator").
        attribute
        end

    max_message_size: INTEGER
            -- Max message size (bytes).
        attribute
        end

feature -- Implementation (from PYTHON_BRIDGE)

    initialize
        do
            -- Create named pipe server via simple_ipc
            -- Listen for client connections
            is_initialized := True
        ensure
            is_initialized: is_initialized
        end

    send_message (a_request: PYTHON_REQUEST)
        require
            bridge_initialized: is_initialized
            request_not_void: a_request /= Void
            request_valid: a_request.is_valid
        do
            -- Serialize request to binary
            -- Frame: [4-byte length][payload]
            -- Write to named pipe
            is_connected := True
            last_message_timestamp := current_time_microseconds
        ensure
            message_sent: is_connected or last_error /= Void
        end

    receive_response: PYTHON_RESPONSE
        require
            bridge_initialized: is_initialized
        do
            -- Read 4-byte length from pipe
            -- Read payload bytes
            -- Deserialize to PYTHON_RESPONSE
            last_response_timestamp := current_time_microseconds
            create Result.make_valid
        ensure
            result_not_void: Result /= Void
        end

    shutdown
        do
            -- Close named pipe
            -- Disconnect client
            is_connected := False
        ensure
            not_connected: not is_connected
        end

feature -- Status Queries

    is_initialized: BOOLEAN
        attribute
        end

    is_connected: BOOLEAN
        attribute
        end

    last_error: detachable STRING_32
        attribute
        end

    last_message_timestamp: INTEGER_64
        attribute
        end

    last_response_timestamp: INTEGER_64
        attribute
        end

invariant
    pipe_name_non_empty: pipe_name /= Void and then pipe_name.count > 0

end
```

---

## Concrete Class: GRPC_PYTHON_BRIDGE (Ready - Design Choice Required)

```eiffel
note
    description: "gRPC RPC bridge implementation. Choose implementation path: direct ISE NET, simple_socket wrapper, or Python delegation."
    author: "Simple Eiffel Contributors"
    dependencies: "simple_grpc, ISE net.ecf (socket I/O available)"
    status: "Ready. Choose path: Option A (direct ISE), Option B (simple_socket), or Option C (Python delegation)"

class
    GRPC_PYTHON_BRIDGE

inherit
    PYTHON_BRIDGE

create
    make_with_host_port

feature {NONE} -- Initialization

    make_with_host_port (a_host: STRING_32; a_port: INTEGER)
            -- Create unconfigured gRPC bridge.
        require
            host_not_void: a_host /= Void
            port_valid: a_port > 0 and a_port < 65536
        do
            host := a_host
            port := a_port
            max_concurrent_streams := 100
            is_initialized := False
            is_connected := False
        ensure
            host_set: host = a_host
            port_set: port = a_port
        end

feature -- Access

    host: STRING_32
            -- Bind address.
        attribute
        end

    port: INTEGER
            -- TCP port.
        attribute
        end

    max_concurrent_streams: INTEGER
            -- Max parallel RPCs.
        attribute
        end

feature -- Implementation (from PYTHON_BRIDGE)

    initialize
        do
            -- Create gRPC service via simple_grpc
            -- Bind socket I/O (NEW requirement)
            -- Listen on host:port
            is_initialized := True
        ensure
            is_initialized: is_initialized
        end

    send_message (a_request: PYTHON_REQUEST)
        require
            bridge_initialized: is_initialized
            request_not_void: a_request /= Void
            request_valid: a_request.is_valid
        do
            -- Encode to Protocol Buffers
            -- Send via gRPC (over socket I/O)
            is_connected := True
            last_message_timestamp := current_time_microseconds
        ensure
            message_sent: is_connected or last_error /= Void
        end

    receive_response: PYTHON_RESPONSE
        require
            bridge_initialized: is_initialized
        do
            -- Receive gRPC response
            -- Decode Protocol Buffers
            last_response_timestamp := current_time_microseconds
            create Result.make_valid
        ensure
            result_not_void: Result /= Void
        end

    shutdown
        do
            -- Close gRPC service
            -- Release socket connections
            is_connected := False
        ensure
            not_connected: not is_connected
        end

feature -- Status Queries

    is_initialized: BOOLEAN
        attribute
        end

    is_connected: BOOLEAN
        attribute
        end

    last_error: detachable STRING_32
        attribute
        end

    last_message_timestamp: INTEGER_64
        attribute
        end

    last_response_timestamp: INTEGER_64
        attribute
        end

invariant
    max_concurrent_positive: max_concurrent_streams > 0

end
```

---

## File Structure

```
src/
├── simple_python.e              -- Library facade
├── python_bridge.e              -- Deferred interface
├── python_message.e             -- Deferred message interface
├── python_request.e             -- Request implementation
├── python_response.e            -- Response implementation
├── python_error.e               -- Error implementation
├── manufacturing_metadata.e     -- Audit trail
├── http/
│   └── http_python_bridge.e     -- HTTP implementation
├── ipc/
│   └── ipc_python_bridge.e      -- IPC implementation (Windows)
└── grpc/
    └── grpc_python_bridge.e     -- gRPC implementation (choose path: direct ISE, simple_socket, or Python)

test/
├── test_app.e                   -- Test runner
├── test_python_request.e        -- Request tests
├── test_python_response.e       -- Response tests
├── test_http_bridge.e           -- HTTP bridge tests
├── test_ipc_bridge.e            -- IPC bridge tests
└── test_grpc_bridge.e           -- gRPC bridge tests
```

---

## Next Step

Proceed to Step 8: VALIDATION.md - Verify that design satisfies all OOSC2 principles, requirements, and quality criteria.

---

End of SPECIFICATION.md
