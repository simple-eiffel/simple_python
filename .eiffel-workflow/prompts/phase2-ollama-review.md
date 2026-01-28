# Eiffel Contract Review Request (Ollama)

You are reviewing Eiffel Design by Contract (DBC) specifications for the simple_python library (Eiffel-Python bridge for validation communication).

Find obvious problems, missing constraints, weak preconditions, and DBC anti-patterns.

## Review Checklist

- [ ] Preconditions that are just `True` (too weak)
- [ ] Postconditions that don't constrain anything
- [ ] Missing invariants
- [ ] Obvious edge cases not handled
- [ ] Missing state transitions (what state are we in after this operation?)
- [ ] Error handling gaps (what happens on failure?)
- [ ] Resource cleanup issues (are resources always released?)
- [ ] Race conditions or SCOOP concerns (detachable/separate keywords)
- [ ] Inconsistent error semantics (when should has_error be true?)

## Contracts Review

### SIMPLE_PYTHON Facade

```eiffel
class SIMPLE_PYTHON
  create make

  feature {NONE} -- Initialization
    make
      -- Initialize library state.
      do
        -- No-op: Bridges are created on demand
      ensure
        -- Library state ready for bridge creation
      end

  feature -- HTTP Bridge Creation
    new_http_bridge (a_host: STRING_32; a_port: INTEGER): HTTP_PYTHON_BRIDGE
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
      require
        pipe_name_not_void: a_pipe_name /= Void and then a_pipe_name.count > 0
      do
        create Result.make_with_pipe_name (a_pipe_name)
      ensure
        result_not_void: Result /= Void
        pipe_set: Result.pipe_name.same_string (a_pipe_name)
        not_initialized: not Result.is_initialized
      end

  invariant
    -- Library has no state; all state is in bridge instances
end
```

### PYTHON_BRIDGE Deferred Interface

```eiffel
deferred class PYTHON_BRIDGE

  feature -- Status Queries
    is_initialized: BOOLEAN
      -- Is bridge initialized?
      deferred end

    is_connected: BOOLEAN
      -- Is bridge currently connected?
      deferred end

    has_error: BOOLEAN
      -- Did last operation fail?
      deferred end

    last_error_message: detachable STRING_32
      -- Error message from last operation
      deferred end

  feature -- Bridge Lifecycle
    initialize: BOOLEAN
      -- Initialize bridge (start HTTP server or open IPC pipe).
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
      require
        not_void: True
      deferred
      ensure
        not_connected: not is_connected
      end

  feature -- Message Operations
    send_message (a_message: PYTHON_MESSAGE): BOOLEAN
      -- Send message through bridge.
      require
        initialized: is_initialized
        message_not_void: a_message /= Void
      deferred
      ensure
        success_or_error_set: Result or has_error
      end

    receive_message: detachable PYTHON_MESSAGE
      -- Receive next message from bridge (blocking).
      require
        initialized: is_initialized
      deferred
      end

  feature -- Configuration
    set_timeout (a_timeout_ms: INTEGER)
      -- Set receive timeout in milliseconds.
      require
        timeout_positive: a_timeout_ms > 0
      deferred
      end

  invariant
    error_implies_not_connected: has_error implies (not is_connected)
end
```

### PYTHON_MESSAGE Base Class

```eiffel
deferred class PYTHON_MESSAGE

  feature {NONE} -- Initialization
    make (a_message_id: STRING_32)
      require
        id_not_empty: a_message_id /= Void and then a_message_id.count > 0
      do
        message_id := a_message_id
        create attributes.make (10)
        timestamp := create {DATE_TIME}.make_now
      ensure
        id_set: message_id.same_string (a_message_id)
        attributes_empty: attributes.count = 0
        timestamp_set: timestamp /= Void
      end

  feature -- Access
    message_id: STRING_32
      -- Unique identifier for this message.

    timestamp: DATE_TIME
      -- When message was created.

    message_type: STRING_32
      -- Type of message (VALIDATION_REQUEST, etc.)
      deferred end

  feature -- Attributes
    attributes: HASH_TABLE [SIMPLE_JSON_VALUE, STRING_32]
      -- Key-value attributes.

  feature -- Attribute Operations
    set_attribute (a_key: STRING_32; a_value: SIMPLE_JSON_VALUE)
      require
        key_not_empty: a_key /= Void and then a_key.count > 0
        value_not_void: a_value /= Void
      do
        attributes.force (a_value, a_key)
      ensure
        attribute_set: attributes.has (a_key) and then attributes [a_key] = a_value
      end

    get_attribute (a_key: STRING_32): detachable SIMPLE_JSON_VALUE
      require
        key_not_empty: a_key /= Void and then a_key.count > 0
      do
        if attributes.has (a_key) then
          Result := attributes [a_key]
        end
      end

    has_attribute (a_key: STRING_32): BOOLEAN
      require
        key_not_empty: a_key /= Void and then a_key.count > 0
      do
        Result := attributes.has (a_key)
      ensure
        result_matches_contains: Result = attributes.has (a_key)
      end

    attribute_count: INTEGER
      do
        Result := attributes.count
      ensure
        result_equals_table_count: Result = attributes.count
      end

  feature -- Serialization
    to_json: SIMPLE_JSON_OBJECT
      deferred
      ensure
        result_not_void: Result /= Void
        has_message_id: Result.has_key ("message_id")
        has_timestamp: Result.has_key ("timestamp")
        has_type: Result.has_key ("type")
      end

    to_binary: ARRAY [NATURAL_8]
      deferred
      ensure
        result_not_void: Result /= Void
        result_not_empty: Result.count > 4
      end

  invariant
    message_id_set: message_id /= Void and then message_id.count > 0
    attributes_not_void: attributes /= Void
    timestamp_set: timestamp /= Void
end
```

### HTTP_PYTHON_BRIDGE and IPC_PYTHON_BRIDGE

Both inherit from PYTHON_BRIDGE and implement all deferred features with Phase 4 TODO stubs.

HTTP has: host, port, timeout_ms, is_initialized, is_connected, has_error, last_error_message, pending_messages queue
IPC has: pipe_name, timeout_ms, message framing (encode_frame/decode_frame with 4-byte big-endian length prefix)
Both track: bytes_sent, bytes_received, messages_sent, messages_received

## Implementation Approach

See: `.eiffel-workflow/approach.md`

Contains detailed algorithms for:
- HTTP initialization (simple_http library)
- IPC frame encoding/decoding (4-byte length prefix)
- Message serialization (JSON)
- Error handling and resource cleanup
- Testing strategy
- Design decisions with rationale

## Issues Found

List issues as:

- **ISSUE**: [description]
- **LOCATION**: [class.feature]
- **SEVERITY**: HIGH / MEDIUM / LOW
- **SUGGESTION**: [how to fix]

## Focus Areas

1. **Correctness**: Do contracts specify intended behavior?
2. **Completeness**: Are all error conditions handled?
3. **Clarity**: Can implementer understand requirements?
4. **Consistency**: Are similar concepts named/handled similarly?
5. **Safety**: Are there resource leaks, race conditions?
