# INTERFACE DESIGN: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Specification Phase:** Step 6 - Public API and User-Facing Design

---

## Overview

This document designs the public API for simple_python, focusing on ergonomics, clarity, and minimal cognitive load for users. The API balances:

- **Simplicity** - Easy for 80% of use cases
- **Extensibility** - Flexibility for 15% advanced cases
- **Safety** - No way to misuse accidentally (contracts enforce safety)

---

## Library-Level API: SIMPLE_PYTHON

The primary entry point. Users create bridges through this facade.

### Creation API

```eiffel
class SIMPLE_PYTHON
        -- simple_python library facade

feature -- HTTP Bridge Creation

    new_http_bridge (a_host: STRING_32; a_port: INTEGER): HTTP_PYTHON_BRIDGE
            -- Create a new HTTP bridge.
            --
            -- Parameters:
            --   a_host: Hostname or IP (e.g., "localhost", "192.168.1.100")
            --   a_port: TCP port (e.g., 8080, 50051)
            --
            -- Returns: Unconfigured bridge (call initialize to start server)
            --
            -- Example:
            --   bridge := simple_python.new_http_bridge ("localhost", 8080)
            --   bridge.set_timeout (5000)
            --   bridge.initialize
        require
            host_not_void: a_host /= Void
            host_not_empty: a_host.count > 0
            port_valid: a_port > 0 and a_port < 65536
        do
            create Result.make_with_host_port (a_host, a_port)
        ensure
            result_not_void: Result /= Void
            result_not_initialized: not Result.is_initialized
        end

feature -- IPC Bridge Creation

    new_ipc_bridge (a_pipe_name: STRING_32): IPC_PYTHON_BRIDGE
            -- Create a new IPC bridge.
            --
            -- Parameters:
            --   a_pipe_name: Named pipe name (e.g., "\\.\pipe\eiffel_validator")
            --
            -- Returns: Unconfigured bridge
            --
            -- Example:
            --   bridge := simple_python.new_ipc_bridge ("\\.\pipe\eiffel_validator")
            --   bridge.initialize
        require
            pipe_name_not_void: a_pipe_name /= Void
            pipe_name_not_empty: a_pipe_name.count > 0
        do
            create Result.make_with_pipe_name (a_pipe_name)
        ensure
            result_not_void: Result /= Void
            result_not_initialized: not Result.is_initialized
        end

feature -- gRPC Bridge Creation

    new_grpc_bridge (a_host: STRING_32; a_port: INTEGER): GRPC_PYTHON_BRIDGE
            -- Create a new gRPC bridge.
            --
            -- Parameters:
            --   a_host: Bind address (e.g., "0.0.0.0", "127.0.0.1")
            --   a_port: TCP port (e.g., 50051)
            --
            -- Returns: Unconfigured bridge
            --
            -- Example:
            --   bridge := simple_python.new_grpc_bridge ("0.0.0.0", 50051)
            --   bridge.set_max_concurrent_streams (100)
            --   bridge.initialize
        require
            host_not_void: a_host /= Void
            host_not_empty: a_host.count > 0
            port_valid: a_port > 0 and a_port < 65536
        do
            create Result.make_with_host_port (a_host, a_port)
        ensure
            result_not_void: Result /= Void
            result_not_initialized: not Result.is_initialized
        end

end
```

---

## Bridge-Level API: PYTHON_BRIDGE

The core interface users interact with for send/receive operations.

### Minimal Usage Pattern

```eiffel
-- Example: Validate a design with HTTP bridge

local
    bridge: PYTHON_BRIDGE
    request: PYTHON_REQUEST
    response: PYTHON_RESPONSE
    lib: SIMPLE_PYTHON
do
    -- Create bridge
    lib := create {SIMPLE_PYTHON}
    bridge := lib.new_http_bridge ("localhost", 8080)

    -- Initialize (start server)
    bridge.initialize

    -- Create request
    create request.make_with_data ("schematic_v2.json")
    request.set_rules (<<"RULE_1", "RULE_2">>)

    -- Send and receive
    bridge.send_message (request)
    response := bridge.receive_response

    -- Check results
    if response.is_valid then
        io.put_string ("Design is valid")
    else
        across response.errors as error loop
            io.put_string ("Error: " + error.item + "%N")
        end
    end

    -- Cleanup
    bridge.shutdown
end
```

### Configuration API (Builder Pattern)

```eiffel
feature -- Configuration (Fluent Builder)

    set_timeout (a_ms: INTEGER): like Current
            -- Set request timeout in milliseconds.
            --
            -- Default: 5000 (5 seconds)
            --
            -- Returns: Current (for chaining)
        require
            positive: a_ms > 0
        do
            -- Implementation
            Result := Current
        ensure
            timeout_set: timeout_ms = a_ms
            result_is_current: Result = Current
        end

    set_max_retries (a_count: INTEGER): like Current
            -- Set maximum retry attempts.
            --
            -- Default: 3
            --
            -- Returns: Current (for chaining)
        require
            non_negative: a_count >= 0
        do
            -- Implementation
            Result := Current
        ensure
            retries_set: max_retries = a_count
            result_is_current: Result = Current
        end

    set_max_message_size (a_bytes: INTEGER): like Current
            -- Set maximum message size.
            --
            -- Default: 10_000_000 (10 MB)
            --
            -- Returns: Current (for chaining)
        require
            positive: a_bytes > 0
        do
            -- Implementation
            Result := Current
        ensure
            size_set: max_message_size = a_bytes
            result_is_current: Result = Current
        end

end
```

### Fluent Configuration Example

```eiffel
-- Example: Configure HTTP bridge with custom settings

bridge := lib.new_http_bridge ("localhost", 8080)
    .set_timeout (10000)              -- 10 second timeout
    .set_max_retries (5)               -- Retry up to 5 times
    .set_max_message_size (50_000_000) -- 50 MB max payload

bridge.initialize
```

---

## Message API: PYTHON_REQUEST

Users create request objects with design data and validation rules.

### Request Creation API

```eiffel
class PYTHON_REQUEST
    inherit PYTHON_MESSAGE
        -- User-facing request creation and configuration

feature -- Creation

    make (a_design_data: STRING_32): PYTHON_REQUEST
            -- Create request with design data.
            --
            -- Parameters:
            --   a_design_data: The design/code to validate (JSON, XML, text, etc.)
            --
            -- Returns: Request object (message_id and timestamp auto-generated)
            --
            -- Example:
            --   request := create {PYTHON_REQUEST}.make ("{ 'board': 'v2' }")
        require
            data_not_void: a_design_data /= Void
            data_not_empty: a_design_data.count > 0
        do
            -- Initialize with generated message_id and timestamp
        ensure
            design_set: design_data = a_design_data
            message_id_generated: message_id /= Void and message_id.count = 36  -- UUID
            is_valid: is_valid
        end

feature -- Configuration

    set_rules (a_rules: ARRAY [STRING_32]): like Current
            -- Set validation rules to apply.
            --
            -- Parameters:
            --   a_rules: List of rule identifiers (e.g., ["RULE_1", "RULE_2"])
            --
            -- Returns: Current (for chaining)
            --
            -- Example:
            --   request.set_rules (<<"RULE_1", "RULE_2">>)
        require
            rules_not_void: a_rules /= Void
            -- May be empty (use default rules)
        do
            validation_rules := a_rules
            Result := Current
        ensure
            rules_set: validation_rules = a_rules
            result_is_current: Result = Current
        end

    set_priority (a_priority: INTEGER): like Current
            -- Set request priority (1=high, 10=low).
            --
            -- Default: 5 (medium priority)
            --
            -- Returns: Current (for chaining)
        require
            valid_range: a_priority >= 1 and a_priority <= 10
        do
            priority := a_priority
            Result := Current
        ensure
            priority_set: priority = a_priority
            result_is_current: Result = Current
        end

    set_with_manufacturing_metadata (
        a_req_id: STRING_32;
        a_test_case: STRING_32;
        a_operator: STRING_32
    ): like Current
            -- Attach manufacturing audit trail metadata.
            --
            -- Parameters:
            --   a_req_id: Requirement identifier (e.g., "REQ-2.3.1")
            --   a_test_case: Test case identifier (e.g., "TC-0045")
            --   a_operator: Operator ID (e.g., "operator_123")
            --
            -- Returns: Current (for chaining)
            --
            -- Example:
            --   request.set_with_manufacturing_metadata ("REQ-2.3", "TC-045", "op_001")
        require
            req_id_not_void: a_req_id /= Void
            test_case_not_void: a_test_case /= Void
            operator_not_void: a_operator /= Void
        do
            create compliance_metadata.make_minimal (a_req_id, a_operator)
            compliance_metadata.set_test_case (a_test_case)
            Result := Current
        ensure
            metadata_attached: compliance_metadata /= Void
            result_is_current: Result = Current
        end

end
```

### Fluent Request Creation Example

```eiffel
-- Example: Create request with rules and manufacturing metadata

request := create {PYTHON_REQUEST}.make ("schematic.json")
    .set_rules (<<"SCHEMATIC_VALIDATION", "TRACE_ROUTING">>)
    .set_priority (3)  -- High priority
    .set_with_manufacturing_metadata ("REQ-2.3.1", "TC-0045", "operator_john")

bridge.send_message (request)
```

---

## Response API: PYTHON_RESPONSE

Users inspect validation results from response.

### Response Inspection API

```eiffel
class PYTHON_RESPONSE
    inherit PYTHON_MESSAGE
        -- User-facing response inspection

feature -- Status

    is_valid: BOOLEAN
            -- Did validation pass (no errors)?
            --
            -- Returns: True if design is valid, False if errors found
            --
            -- Example:
            --   if response.is_valid then
            --       io.put_string ("Design is valid")
            --   end
        deferred
        end

    error_count: INTEGER
            -- How many errors found?
            --
            -- Returns: Number of validation failures
            --
            -- Example:
            --   io.put_string ("Found " + error_count.out + " errors")
        deferred
        end

    warning_count: INTEGER
            -- How many warnings found?
            --
            -- Returns: Number of non-critical issues
        deferred
        end

feature -- Access

    errors: ARRAY [STRING_32]
            -- List of validation errors.
            --
            -- Returns: Array of error messages (empty if is_valid)
            --
            -- Example:
            --   across response.errors as err loop
            --       io.put_string ("Error: " + err.item + "%N")
            --   end
        deferred
        ensure
            non_void: Result /= Void
            empty_if_valid: is_valid implies Result.count = 0
        end

    warnings: ARRAY [STRING_32]
            -- List of non-critical warnings.
            --
            -- Returns: Array of warning messages (may be empty)
        deferred
        ensure
            non_void: Result /= Void
        end

    validation_duration_ms: INTEGER
            -- How long did validation take?
            --
            -- Returns: Milliseconds (useful for performance monitoring)
        deferred
        ensure
            non_negative: Result >= 0
        end

feature -- Evidence

    evidence_url: detachable STRING_32
            -- URL to stored validation evidence.
            --
            -- Returns: URL if available (Void if not stored)
            --
            -- Example:
            --   if attached response.evidence_url as url then
            --       io.put_string ("Evidence: " + url)
            --   end
        deferred
        end

end
```

### Response Inspection Examples

```eiffel
-- Example 1: Check validity

if response.is_valid then
    io.put_string ("Design passed all validation rules")
else
    io.put_string ("Design has " + response.error_count.out + " errors")
end

-- Example 2: Iterate errors

across response.errors as error loop
    io.put_string ("Error: " + error.item + "%N")
end

-- Example 3: Check warnings

if response.warning_count > 0 then
    io.put_string ("Warnings: ")
    across response.warnings as warning loop
        io.put_string (warning.item + "; ")
    end
end

-- Example 4: Monitor performance

io.put_string ("Validation took " + response.validation_duration_ms.out + "ms")

-- Example 5: Access evidence

if attached response.evidence_url as url then
    io.put_string ("Full evidence at: " + url)
end
```

---

## Error Handling API

Users handle errors gracefully with domain-specific error information.

### Error Detection API

```eiffel
class PYTHON_ERROR
    inherit PYTHON_MESSAGE
        -- User-facing error inspection

feature -- Error Information

    error_code: INTEGER
            -- Numeric error code.
            --
            -- Returns: 400 (client), 500 (server), 503 (timeout)
            --
            -- Example:
            --   if error.error_code = 400 then
            --       io.put_string ("Bad request: " + error.error_message)
            --   end
        deferred
        end

    error_message: STRING_32
            -- Human-readable error description.
            --
            -- Returns: English error message
            --
            -- Example:
            --   io.put_string ("Error: " + error.error_message)
        deferred
        end

feature -- Error Classification

    is_client_error: BOOLEAN
            -- Did Python send malformed request?
            --
            -- Returns: True if client (400), False if server (5xx)
            --
            -- Example:
            --   if error.is_client_error then
            --       io.put_string ("Bad request (don't retry)")
            --   end
        deferred
        end

    is_server_error: BOOLEAN
            -- Did Eiffel encounter internal error?
            --
            -- Returns: True if server error (5xx), False if client (4xx)
        deferred
        end

    is_retriable: BOOLEAN
            -- Should Python retry this request?
            --
            -- Returns: True if transient error (5xx), False if permanent (4xx)
            --
            -- Example:
            --   if error.is_retriable then
            --       wait_and_retry ()
            --   end
        deferred
        end

end
```

### Error Handling Example

```eiffel
-- Example: Handle errors with retry logic

local
    request: PYTHON_REQUEST
    response: PYTHON_RESPONSE
    error: PYTHON_ERROR
    retry_count: INTEGER
do
    from
        retry_count := 0
    until
        retry_count > 3 or attached response
    loop
        bridge.send_message (request)

        -- Try to receive response
        if bridge.last_error /= Void then
            error := create {PYTHON_ERROR}.make_from_bridge_error (bridge)

            if error.is_retriable then
                retry_count := retry_count + 1
                wait (1000)  -- Wait 1 second before retry
            else
                io.put_string ("Fatal error: " + error.error_message)
                retry_count := 999  -- Exit loop
            end
        else
            response := bridge.receive_response
        end
    end
end
```

---

## Type-Safe Request/Response Pattern

### Implementing Custom Validators

```eiffel
-- Example: Custom validator implementation

class BOARD_DESIGN_VALIDATOR
    -- User-written validator

feature -- Validation

    validate (a_design: STRING_32): PYTHON_RESPONSE
            -- Custom validation logic.
        local
            response: PYTHON_RESPONSE
        do
            -- Parse design
            if not is_valid_json (a_design) then
                create response.make_with_error ("Design must be valid JSON")
            else
                -- Run custom validation rules
                response := run_validation_rules (a_design)
            end
            Result := response
        end

end
```

---

## Streaming API (Phase 2 Preview)

```eiffel
feature -- Streaming (gRPC, Phase 2)

    stream_validate (a_request_stream: ITERABLE [PYTHON_REQUEST]): ITERABLE [PYTHON_RESPONSE]
            -- Stream multiple requests, receive stream of responses.
            --
            -- Phase 2 feature (gRPC bi-directional streaming)
            --
            -- Parameters:
            --   a_request_stream: Iterator of requests
            --
            -- Returns: Iterator of responses (as they arrive)
            --
            -- Example (Phase 2):
            --   responses := bridge.stream_validate (large_design_chunks)
            --   across responses as response loop
            --       if not response.item.is_valid then
            --           io.put_string ("Error in chunk: " + response.item.errors [1])
            --           exit  -- Fail fast
            --       end
            --   end
        deferred
        ensure
            result_not_void: Result /= Void
        end

end
```

---

## API Design Principles Applied

### 1. Principle of Least Surprise

- `new_*` methods create new instances (not reuse)
- Fluent API returns Current for chaining
- `is_valid` returns boolean (not throws exception)

### 2. Fail-Safe Defaults

```eiffel
-- HTTP timeout defaults to 5 seconds (reasonable for most)
-- Max retries defaults to 3 (good for transient failures)
-- Message size limit defaults to 10 MB (covers 99% of designs)
```

### 3. Explicit Error Handling

- No exceptions for business logic (is_valid instead of exception)
- PYTHON_ERROR separates error communication from validation results
- `is_retriable` makes retry logic obvious

### 4. Minimal Cognitive Load

```eiffel
-- Good: Simple, obvious intent
request := create {PYTHON_REQUEST}.make ("design.json")
    .set_rules (<<"RULE_1">>)

-- Bad (verbose):
request := create {PYTHON_REQUEST}
request.set_design_data ("design.json")
request.add_rule ("RULE_1")
request.set_priority (5)
request.set_correlation_id (generate_uuid)
request.set_message_type ("validate_request")
request.set_timestamp (current_microseconds)
```

### 5. Contract-Driven Safety

- Preconditions prevent invalid inputs before execution
- Postconditions guarantee outputs after execution
- Invariants maintain class consistency

---

## Next Step

Proceed to Step 7: SPECIFICATION.md - Synthesize all design into formal class specifications (full Eiffel code with contracts).

---

End of INTERFACE-DESIGN.md
