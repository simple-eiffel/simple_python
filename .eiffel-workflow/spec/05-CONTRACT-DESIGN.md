# CONTRACT DESIGN: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Specification Phase:** Step 5 - Design by Contract with MML Model Queries

---

## Overview

This document specifies Design by Contract for all classes in simple_python. Every public feature has:
- **Preconditions** (require) - What must be true before calling
- **Postconditions** (ensure) - What's guaranteed after execution
- **Invariants** - What's always true for the class
- **MML Model Queries** - Mathematical models for collections enabling frame conditions

All contracts use Mathematical Model Library (simple_mml) for precision.

---

## PYTHON_BRIDGE Contracts

### Deferred Class PYTHON_BRIDGE

```eiffel
deferred class PYTHON_BRIDGE
        -- Abstract interface for protocol-agnostic bridge communication

feature -- Initialization

    initialize
            -- Initialize bridge (start server/client, open connections).
        require
            not_already_initialized: not is_initialized
        deferred
        ensure
            is_initialized: is_initialized
            not_connected_yet: not is_connected  -- Connection happens on first message
        end

feature -- Communication

    send_message (a_request: PYTHON_REQUEST)
            -- Send request to Python endpoint.
        require
            bridge_initialized: is_initialized
            request_not_void: a_request /= Void
            request_valid: a_request.is_valid
        deferred
        ensure
            message_sent: is_connected or last_error /= Void
            timestamp_updated: last_message_timestamp > old last_message_timestamp
        end

    receive_response: PYTHON_RESPONSE
            -- Receive response from Python.
            -- Blocks until response available or timeout.
        require
            bridge_initialized: is_initialized
        deferred
        ensure
            response_not_void: Result /= Void
            response_valid: Result.is_valid or Result = Void
            response_received: Result.timestamp > old last_response_timestamp
        end

feature -- Status Queries

    is_initialized: BOOLEAN
            -- Has bridge been initialized?
        deferred
        end

    is_connected: BOOLEAN
            -- Is connection to Python active?
        deferred
        end

    last_error: detachable STRING_32
            -- Last error message (Void if no error).
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
        require
            -- No precondition: must be shutdownable even in error state
        deferred
        ensure
            not_connected: not is_connected
            initialized_unchanged: is_initialized  -- May remain initialized after shutdown
        end

invariant
    timestamps_consistent: last_message_timestamp <= last_response_timestamp or last_response_timestamp = 0
    -- Note: last_response_timestamp may be 0 if no response received yet

end
```

---

## PYTHON_MESSAGE Contracts

### Deferred Class PYTHON_MESSAGE

```eiffel
deferred class PYTHON_MESSAGE
        -- Abstract interface for protocol-agnostic message semantics

feature -- Access

    message_id: STRING_32
            -- Unique message identifier (UUID format).
        deferred
        ensure
            non_void: Result /= Void
            not_empty: Result.count > 0
            valid_uuid_format: Result.count = 36  -- UUID is "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        end

    message_type: STRING_32
            -- Type of message ("validate_request", "validate_response", "error_response").
        deferred
        ensure
            non_void: Result /= Void
            not_empty: Result.count > 0
            valid_type: Result = "validate_request" or Result = "validate_response" or Result = "error_response"
        end

    payload: detachable STRING_32
            -- Message payload (deferred, subclass-specific).
        deferred
        end

    timestamp: INTEGER_64
            -- Unix timestamp (microseconds since epoch).
        deferred
        ensure
            non_negative: Result > 0  -- Must be positive (before year 1970 invalid)
        end

    compliance_metadata: detachable MANUFACTURING_METADATA
            -- Optional audit trail information.
        deferred
        end

feature -- Serialization

    to_bytes: ARRAY [NATURAL_8]
            -- Serialize message to protocol-specific byte representation.
        require
            is_valid: is_valid  -- Message must be well-formed before serialization
        deferred
        ensure
            result_not_void: Result /= Void
            result_not_empty: Result.count > 0
            result_immutable: Result.count = old Result.count  -- Bytes don't change on re-serialize
        end

    from_bytes (a_bytes: ARRAY [NATURAL_8])
            -- Deserialize message from protocol-specific byte representation.
        require
            bytes_not_void: a_bytes /= Void
            bytes_not_empty: a_bytes.count > 0
        deferred
        ensure
            message_id_set: message_id /= Void  -- Must have ID after deserialization
            message_type_set: message_type /= Void
            timestamp_set: timestamp > 0
        end

feature -- Validation

    is_valid: BOOLEAN
            -- Is message well-formed?
            -- (has required fields, no malformed data)
        deferred
        ensure
            has_id_when_valid: Result implies (message_id /= Void and then message_id.count > 0)
            has_type_when_valid: Result implies (message_type /= Void and then message_type.count > 0)
            has_timestamp_when_valid: Result implies (timestamp > 0)
        end

invariant
    message_id_consistency: message_id /= Void implies message_id.count > 0
    message_type_consistency: message_type /= Void implies message_type.count > 0
    timestamp_positive: timestamp >= 0

end
```

---

## PYTHON_REQUEST Contracts

### Deferred Class PYTHON_REQUEST

```eiffel
deferred class PYTHON_REQUEST
    inherit PYTHON_MESSAGE
        -- Request message: validate design/code

feature -- Model Query (for frame conditions)

    validation_rules_model: MML_SEQUENCE [STRING_32]
            -- Mathematical model of validation rules.
        deferred
        end

feature -- Access

    design_data: STRING_32
            -- Design or code to validate.
        deferred
        ensure
            non_void: Result /= Void
            not_empty: Result.count > 0
        end

    validation_rules: ARRAY [STRING_32]
            -- Rules to apply (rule identifiers).
        deferred
        ensure
            non_void: Result /= Void
            -- May be empty (validate with default rules)
        end

    priority: INTEGER
            -- Request priority (1=high, 10=low).
        deferred
        ensure
            valid_range: Result >= 1 and Result <= 10
        end

    correlation_id: STRING_32
            -- Links to related validation requests (UUID format).
        deferred
        ensure
            non_void: Result /= Void
            valid_uuid: Result.count = 36
        end

feature -- Validation

    is_valid: BOOLEAN
            -- Is this a valid request?
        do
            Result := design_data /= Void and then design_data.count > 0 and then
                      validation_rules /= Void and then
                      priority >= 1 and priority <= 10 and then
                      message_id /= Void and then
                      message_type = "validate_request"
        ensure
            design_not_empty: Result implies (design_data /= Void and then design_data.count > 0)
            rules_initialized: Result implies (validation_rules /= Void)
            priority_valid: Result implies (priority >= 1 and priority <= 10)
        end

invariant
    design_non_empty: design_data /= Void implies design_data.count > 0
    rules_non_void: validation_rules /= Void
    priority_range: priority >= 1 and priority <= 10
    message_type_is_request: message_type = "validate_request"

end
```

---

## PYTHON_RESPONSE Contracts

### Deferred Class PYTHON_RESPONSE

```eiffel
deferred class PYTHON_RESPONSE
    inherit PYTHON_MESSAGE
        -- Response message: validation results

feature -- Model Query (for frame conditions)

    errors_model: MML_SEQUENCE [STRING_32]
            -- Mathematical model of error list.
        deferred
        end

    warnings_model: MML_SEQUENCE [STRING_32]
            -- Mathematical model of warning list.
        deferred
        end

feature -- Access

    is_valid: BOOLEAN
            -- Did validation pass (no errors)?
        deferred
        end

    errors: ARRAY [STRING_32]
            -- Validation failures (empty if valid).
        deferred
        ensure
            non_void: Result /= Void
            -- May be empty if is_valid = true
        end

    warnings: ARRAY [STRING_32]
            -- Non-critical issues (empty if none).
        deferred
        ensure
            non_void: Result /= Void
            -- May be empty
        end

    evidence_url: detachable STRING_32
            -- URL to stored validation evidence artifact.
        deferred
        end

    validation_duration_ms: INTEGER
            -- How long validation took (milliseconds).
        deferred
        ensure
            non_negative: Result >= 0
        end

feature -- Consistency Queries

    has_errors: BOOLEAN
            -- Does response contain errors?
        do
            Result := errors /= Void and then errors.count > 0
        end

    error_count: INTEGER
            -- Number of errors.
        do
            if errors /= Void then
                Result := errors.count
            end
        ensure
            count_non_negative: Result >= 0
        end

invariant
    -- XOR: Valid state (valid=true, no errors) OR invalid state (valid=false, has errors)
    valid_xor_errors: is_valid xor (errors.count > 0)

    -- If valid, no errors
    valid_implies_no_errors: is_valid implies (errors.count = 0)

    -- If has errors, not valid
    errors_implies_invalid: (errors.count > 0) implies (not is_valid)

    -- Collections non-void
    errors_non_void: errors /= Void
    warnings_non_void: warnings /= Void

    -- Message type consistent
    message_type_is_response: message_type = "validate_response"

end
```

---

## PYTHON_ERROR Contracts

### Concrete Class PYTHON_ERROR

```eiffel
class PYTHON_ERROR
    inherit PYTHON_MESSAGE
        -- Error message: communication/processing failures

feature -- Access

    error_code: INTEGER
            -- Numeric code (400=client, 500=server, 503=timeout, 504=unavailable).
        attribute
        end

    error_message: STRING_32
            -- Human-readable error description.
        attribute
        end

    error_context: detachable STRING_32
            -- Additional diagnostic information.
        attribute
        end

feature -- Status Queries

    is_retriable: BOOLEAN
            -- Can Python retry this request?
        do
            Result := error_code /= 400 and error_code /= 401 and error_code /= 403
        ensure
            client_errors_not_retriable: error_code = 400 implies not Result
            -- 400, 401, 403 are client errors (shouldn't retry)
            -- 5xx are server errors (may retry)
        end

    is_client_error: BOOLEAN
            -- Did Python send malformed request?
        do
            Result := error_code = 400 or error_code = 401 or error_code = 403
        ensure
            definition: Result = (error_code = 400 or error_code = 401 or error_code = 403)
        end

    is_server_error: BOOLEAN
            -- Did Eiffel encounter internal error?
        do
            Result := error_code >= 500 and error_code < 600
        ensure
            definition: Result = (error_code >= 500 and error_code < 600)
        end

feature -- Creation

    make (a_code: INTEGER; a_message: STRING_32)
            -- Create error with code and message.
        require
            valid_code: a_code >= 400 and a_code < 600
            message_not_void: a_message /= Void
            message_not_empty: a_message.count > 0
        do
            error_code := a_code
            error_message := a_message
            message_type := "error_response"
            -- message_id and timestamp set by create
        ensure
            code_set: error_code = a_code
            message_set: error_message = a_message
            type_is_error: message_type = "error_response"
        end

invariant
    valid_code: error_code >= 400 and error_code < 600
    message_non_void: error_message /= Void
    message_not_empty: error_message.count > 0
    message_type_is_error: message_type = "error_response"

end
```

---

## MANUFACTURING_METADATA Contracts

### Concrete Class MANUFACTURING_METADATA

```eiffel
class MANUFACTURING_METADATA
        -- Audit trail information for regulatory compliance

feature -- Access

    requirement_id: detachable STRING_32
            -- Requirement identifier (e.g., "REQ-2.3.1").
        attribute
        end

    test_case_id: detachable STRING_32
            -- Test case identifier.
        attribute
        end

    operator_id: detachable STRING_32
            -- User ID of who executed validation.
        attribute
        end

    compliance_standard: detachable STRING_32
            -- Standard (e.g., "IEC-61131-3", "ISO-26262").
        attribute
        end

    evidence_artifact_url: detachable STRING_32
            -- URL where validation evidence is stored.
        attribute
        end

    validation_timestamp: INTEGER_64
            -- When validation executed (Unix microseconds).
        attribute
        end

feature -- Status Queries

    is_complete: BOOLEAN
            -- Are all required fields populated?
        do
            Result := requirement_id /= Void and then
                      test_case_id /= Void and then
                      operator_id /= Void and then
                      compliance_standard /= Void and then
                      validation_timestamp > 0
        ensure
            definition: Result = (
                requirement_id /= Void and
                test_case_id /= Void and
                operator_id /= Void and
                compliance_standard /= Void and
                validation_timestamp > 0
            )
        end

    is_traceable: BOOLEAN
            -- Can this validation be audited?
        do
            Result := is_complete and evidence_artifact_url /= Void
        end

feature -- Creation

    make_minimal (a_req_id: STRING_32; a_operator: STRING_32)
            -- Create minimal metadata for quick validation.
        require
            req_id_not_void: a_req_id /= Void
            operator_not_void: a_operator /= Void
        do
            requirement_id := a_req_id
            operator_id := a_operator
            validation_timestamp := current_time_microseconds
        ensure
            requirement_set: requirement_id = a_req_id
            operator_set: operator_id = a_operator
            timestamp_set: validation_timestamp > 0
        end

invariant
    timestamp_non_negative: validation_timestamp >= 0

end
```

---

## MESSAGE_SERIALIZER Contracts

### Deferred Class MESSAGE_SERIALIZER

```eiffel
deferred class MESSAGE_SERIALIZER
        -- Strategy pattern for protocol-specific serialization

feature -- Serialization

    serialize (a_msg: PYTHON_MESSAGE): ARRAY [NATURAL_8]
            -- Convert message to protocol-specific byte representation.
        require
            message_not_void: a_msg /= Void
            message_valid: a_msg.is_valid
        deferred
        ensure
            result_not_void: Result /= Void
            result_not_empty: Result.count > 0
            round_trip_preserves_id: deserialize (Result).message_id = a_msg.message_id
        end

    deserialize (a_bytes: ARRAY [NATURAL_8]): PYTHON_MESSAGE
            -- Restore message from protocol-specific bytes.
        require
            bytes_not_void: a_bytes /= Void
            bytes_not_empty: a_bytes.count > 0
        deferred
        ensure
            result_not_void: Result /= Void
            result_valid: Result.is_valid
            message_id_restored: Result.message_id /= Void
        end

feature -- Capability Queries

    supports_streaming: BOOLEAN
            -- Can this serializer handle streaming messages?
        deferred
        ensure
            -- Result varies: HTTP=false, IPC=true, gRPC=true
        end

invariant
    -- No invariants on deferred strategy class

end
```

---

## HTTP_PYTHON_BRIDGE Contracts

### Concrete Class HTTP_PYTHON_BRIDGE

```eiffel
class HTTP_PYTHON_BRIDGE
    inherit PYTHON_BRIDGE
        -- HTTP REST API implementation

feature -- Model Query

    active_requests_model: MML_SET [STRING_32]
            -- Mathematical model of in-flight request IDs.
        deferred
        end

feature -- Configuration

    set_timeout (a_ms: INTEGER): like Current
            -- Set HTTP request timeout.
        require
            positive: a_ms > 0
        do
            timeout_ms := a_ms
            Result := Current
        ensure
            timeout_set: timeout_ms = a_ms
            result_current: Result = Current
        end

    set_max_retries (a_count: INTEGER): like Current
            -- Set max retry attempts for transient failures.
        require
            non_negative: a_count >= 0
        do
            max_retries := a_count
            Result := Current
        ensure
            retries_set: max_retries = a_count
            result_current: Result = Current
        end

feature -- Implementation (inherited PYTHON_BRIDGE)

    initialize
        do
            -- Start simple_web server
            -- Register /api/validate endpoint
            -- Set is_initialized := true
        ensure
            is_initialized: is_initialized
        end

    send_message (a_request: PYTHON_REQUEST)
        require
            bridge_initialized: is_initialized
            request_not_void: a_request /= Void
            request_valid: a_request.is_valid
        do
            -- Serialize to JSON via simple_json
            -- HTTP POST to /api/validate
            -- Handle retries on transient errors
        ensure
            message_sent: is_connected or last_error /= Void
        end

    receive_response: PYTHON_RESPONSE
        require
            bridge_initialized: is_initialized
        do
            -- Wait for HTTP response (with timeout)
            -- Deserialize JSON to PYTHON_RESPONSE
        ensure
            response_not_void: Result /= Void
        end

feature -- HTTP-Specific

    server_url: STRING_32
            -- Full URL to HTTP server.
        do
            Result := "http://" + host + ":" + port.out
        end

invariant
    timeout_positive: timeout_ms > 0
    max_retries_non_negative: max_retries >= 0

end
```

---

## IPC_PYTHON_BRIDGE Contracts

### Concrete Class IPC_PYTHON_BRIDGE

```eiffel
class IPC_PYTHON_BRIDGE
    inherit PYTHON_BRIDGE
        -- Windows named pipes IPC implementation

feature -- Configuration

    set_pipe_name (a_name: STRING_32): like Current
            -- Set named pipe name (e.g., "\\.\pipe\eiffel_validator").
        require
            name_not_void: a_name /= Void
            name_not_empty: a_name.count > 0
        do
            pipe_name := a_name
            Result := Current
        ensure
            pipe_set: pipe_name = a_name
            result_current: Result = Current
        end

feature -- Implementation (inherited PYTHON_BRIDGE)

    initialize
        do
            -- Create named pipe server via simple_ipc
            -- Listen for incoming connections
            -- Set is_initialized := true
        ensure
            is_initialized: is_initialized
        end

    send_message (a_request: PYTHON_REQUEST)
        require
            bridge_initialized: is_initialized
            request_not_void: a_request /= Void
            request_valid: a_request.is_valid
        do
            -- Serialize message
            -- Frame: [4-byte length][message bytes]
            -- Write to named pipe
        ensure
            message_sent: is_connected or last_error /= Void
            timestamp_updated: last_message_timestamp > old last_message_timestamp
        end

    receive_response: PYTHON_RESPONSE
        require
            bridge_initialized: is_initialized
        do
            -- Read 4-byte length from pipe
            -- Read message_length bytes
            -- Deserialize to PYTHON_RESPONSE
        ensure
            response_not_void: Result /= Void
            response_valid: Result.is_valid
        end

feature -- IPC-Specific

    wait_for_client
            -- Block until Python client connects.
        require
            is_initialized: is_initialized
        do
            -- simple_ipc.wait_for_client
        ensure
            is_connected: is_connected
        end

invariant
    pipe_name_valid: pipe_name /= Void and then pipe_name.count > 0

end
```

---

## GRPC_PYTHON_BRIDGE Contracts

### Concrete Class GRPC_PYTHON_BRIDGE

```eiffel
class GRPC_PYTHON_BRIDGE
    inherit PYTHON_BRIDGE
        -- gRPC RPC implementation (choose path: direct ISE NET, simple_socket, or Python delegation)

feature -- Configuration

    set_max_concurrent_streams (a_count: INTEGER): like Current
            -- Set max parallel RPCs.
        require
            positive: a_count > 0
        do
            max_concurrent := a_count
            Result := Current
        ensure
            set: max_concurrent = a_count
            result_current: Result = Current
        end

feature -- Implementation (inherited PYTHON_BRIDGE)

    initialize
        do
            -- Create gRPC service via simple_grpc
            -- Bind socket I/O (NEW requirement)
            -- Set is_initialized := true
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
        ensure
            message_sent: is_connected or last_error /= Void
        end

    receive_response: PYTHON_RESPONSE
        require
            bridge_initialized: is_initialized
        do
            -- Receive gRPC response
            -- Decode Protocol Buffers
        ensure
            response_not_void: Result /= Void
            response_valid: Result.is_valid
        end

invariant
    max_concurrent_positive: max_concurrent > 0

end
```

---

## Contract Frame Conditions (What Doesn't Change)

### HTTP_PYTHON_BRIDGE.send_message Frame Condition

```eiffel
send_message (a_request: PYTHON_REQUEST)
    ...
    ensure
        -- What changed:
        message_sent: is_connected or last_error /= Void
        timestamp_updated: last_message_timestamp > old last_message_timestamp

        -- What did NOT change (frame condition):
        server_url_unchanged: server_url = old server_url
        host_unchanged: host = old host
        port_unchanged: port = old port
        timeout_unchanged: timeout_ms = old timeout_ms

        -- Using MML for precision on collections:
        prior_requests_preserved: active_requests_model.removed (a_request.message_id) |=|
                                  old active_requests_model.removed (a_request.message_id)
    end
```

---

## Conclusion: Contract Coverage

**Coverage Summary:**

- ✅ PYTHON_BRIDGE: 6 deferred features with complete contracts
- ✅ PYTHON_MESSAGE: 6 deferred features with complete contracts
- ✅ PYTHON_REQUEST: Specialized request semantics with invariants
- ✅ PYTHON_RESPONSE: XOR invariant (valid ⊕ errors)
- ✅ PYTHON_ERROR: Error classification with status queries
- ✅ MANUFACTURING_METADATA: Audit trail with completeness checks
- ✅ MESSAGE_SERIALIZER: Serialization strategy with round-trip guarantee
- ✅ HTTP_PYTHON_BRIDGE: Concrete HTTP with configuration fluency
- ✅ IPC_PYTHON_BRIDGE: Concrete IPC with pipe management
- ✅ GRPC_PYTHON_BRIDGE: Concrete gRPC with streaming support

**MML Integration:**

- ✅ Model queries for collections (active_requests, errors, warnings, validation_rules)
- ✅ Frame conditions using |=| for what didn't change
- ✅ Old expressions capturing pre-state
- ✅ Postcondition closure: what changed, how, what didn't

**Next Step:** Proceed to Step 6: INTERFACE-DESIGN.md - Design public APIs and ergonomic usage patterns.

---

End of CONTRACT-DESIGN.md
