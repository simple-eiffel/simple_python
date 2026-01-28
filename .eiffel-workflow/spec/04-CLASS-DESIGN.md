# CLASS DESIGN: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Specification Phase:** Step 4 - Apply OOSC2 Principles to Class Architecture

---

## Overview

This document applies OOSC2 (Object-Oriented Software Construction, 2nd Edition) principles to design the class structure for simple_python. Every class follows:

1. **Single Responsibility Principle** - One reason to change
2. **Open/Closed Principle** - Open for extension, closed for modification via inheritance
3. **Liskov Substitution Principle** - Derived classes preserve parent contracts
4. **Interface Segregation** - Classes don't depend on methods they don't use
5. **Command-Query Separation** - Commands modify state, queries don't
6. **Uniform Access Principle** - Attributes and functions interchangeable syntactically

---

## Class Inventory

### Core Facade Classes

| Class | Role | Single Responsibility | Inherits From |
|-------|------|----------------------|----------------|
| SIMPLE_PYTHON | Library facade | Coordinate bridge creation and access | ANY |
| PYTHON_BRIDGE | Bridge interface | Define protocol-agnostic bridge semantics | ANY (deferred) |
| PYTHON_MESSAGE | Message interface | Define protocol-agnostic message contract | ANY (deferred) |

### Bridge Implementations

| Class | Role | Single Responsibility | Inherits From |
|-------|------|----------------------|----------------|
| HTTP_PYTHON_BRIDGE | HTTP bridge | Manage HTTP REST communication | PYTHON_BRIDGE |
| IPC_PYTHON_BRIDGE | IPC bridge | Manage Windows named pipe communication | PYTHON_BRIDGE |
| GRPC_PYTHON_BRIDGE | gRPC bridge | Manage gRPC RPC communication | PYTHON_BRIDGE |

### Message Classes

| Class | Role | Single Responsibility | Inherits From |
|-------|------|----------------------|----------------|
| PYTHON_REQUEST | Request message | Represent validation request | PYTHON_MESSAGE |
| PYTHON_RESPONSE | Response message | Represent validation results | PYTHON_MESSAGE |
| PYTHON_ERROR | Error message | Represent error condition | PYTHON_MESSAGE |

### Data Classes

| Class | Role | Single Responsibility | Inherits From |
|-------|------|----------------------|----------------|
| MANUFACTURING_METADATA | Metadata | Hold audit trail information | ANY |
| MESSAGE_FRAME | Frame data | Hold protocol-level framing info | ANY |

### Serializer Classes

| Class | Role | Single Responsibility | Inherits From |
|-------|------|----------------------|----------------|
| MESSAGE_SERIALIZER | Serializer interface | Define serialization contract | ANY (deferred) |
| HTTP_MESSAGE_SERIALIZER | JSON serializer | Serialize messages to JSON (simple_json) | MESSAGE_SERIALIZER |
| IPC_MESSAGE_SERIALIZER | Binary serializer | Serialize messages to binary with framing | MESSAGE_SERIALIZER |
| GRPC_MESSAGE_SERIALIZER | Protobuf serializer | Serialize messages to Protocol Buffers | MESSAGE_SERIALIZER |

### Server Root Classes (Executable Targets)

| Class | Role | Single Responsibility | Inherits From |
|-------|------|----------------------|----------------|
| HTTP_PYTHON_BRIDGE_SERVER | HTTP server | Main entry point for http_bridge target | ANY |
| IPC_PYTHON_BRIDGE_SERVER | IPC server | Main entry point for ipc_bridge target | ANY |
| GRPC_PYTHON_BRIDGE_SERVER | gRPC server | Main entry point for grpc_bridge target | ANY |

---

## Design Decisions by OOSC2 Principle

### 1. Single Responsibility Principle

**PYTHON_BRIDGE** - ONE reason to change: When bridge protocol semantics evolve (init/send/receive/shutdown contract changes)
- Does NOT handle serialization (delegated to MESSAGE_SERIALIZER)
- Does NOT handle message creation (delegated to PYTHON_REQUEST, PYTHON_RESPONSE)
- Does NOT handle error formatting (delegated to PYTHON_ERROR)

**PYTHON_MESSAGE** - ONE reason to change: When message structure changes (add field, change field semantics)
- Does NOT handle protocol specifics (delegated to subclasses)
- Does NOT handle serialization implementation (delegated to MESSAGE_SERIALIZER)

**MESSAGE_SERIALIZER** - ONE reason to change: When serialization format evolves for a protocol
- HTTP_MESSAGE_SERIALIZER: JSON format changes
- IPC_MESSAGE_SERIALIZER: Binary framing changes
- GRPC_MESSAGE_SERIALIZER: Protocol Buffers schema changes

**Violation Check:** Would you describe this class in one sentence without "and"?
- PYTHON_BRIDGE: "Abstract interface for protocol-independent bridge communication" ✓
- HTTP_PYTHON_BRIDGE: "Concrete HTTP bridge implementation using simple_http/simple_web" ✓
- MESSAGE_SERIALIZER: "Strategy for converting messages to/from protocol-specific bytes" ✓

---

### 2. Open/Closed Principle

**Closed for modification:** PYTHON_BRIDGE interface defines contract that derived classes CANNOT change.
- HTTP_PYTHON_BRIDGE, IPC_PYTHON_BRIDGE, GRPC_PYTHON_BRIDGE cannot weaken postconditions or violate invariants
- Eiffel's contract inheritance enforces this

**Open for extension:** New protocols can be added without modifying existing code.
- Example: Future WEBSOCKET_PYTHON_BRIDGE just extends PYTHON_BRIDGE
- Existing HTTP/IPC/gRPC code unchanged

**Example:** Adding new protocol

```eiffel
class WEBSOCKET_PYTHON_BRIDGE
    inherit PYTHON_BRIDGE
        -- Implements all deferred features
        -- Does NOT modify HTTP_PYTHON_BRIDGE or IPC_PYTHON_BRIDGE
end
```

---

### 3. Liskov Substitution Principle

**Contract Invariance:** All PYTHON_BRIDGE subclasses satisfy identical contracts.

```eiffel
-- This code works for ANY bridge implementation
procedure validate_with_bridge (a_bridge: PYTHON_BRIDGE; a_request: PYTHON_REQUEST)
    require
        a_bridge.is_initialized
        a_request.is_valid
    do
        a_bridge.send_message (a_request)
        response := a_bridge.receive_response
        if response.is_valid then
            -- Process validation success
        else
            -- Process errors
        end
    ensure
        a_bridge.is_connected
    end
```

This code works identically whether `a_bridge` is HTTP_PYTHON_BRIDGE, IPC_PYTHON_BRIDGE, or GRPC_PYTHON_BRIDGE.

**Enforcement:** Eiffel's contract inheritance; derived classes cannot weaken preconditions or change postconditions.

---

### 4. Interface Segregation Principle

**PYTHON_BRIDGE interface segregated by concern:**

```eiffel
deferred class PYTHON_BRIDGE

feature -- Initialization (segregated concern)
    initialize
    shutdown

feature -- Communication (segregated concern)
    send_message (a_request: PYTHON_REQUEST)
    receive_response: PYTHON_RESPONSE

feature -- Status (segregated concern)
    is_initialized: BOOLEAN
    is_connected: BOOLEAN
    last_error: detachable STRING_32

end
```

**Clients use only what they need:**
- Test framework cares about `is_initialized` and `last_error` (status queries)
- Application code cares about `send_message`/`receive_response` (communication)
- Neither client forced to know about ALL features

**Segregated Serializers:**

```eiffel
deferred class MESSAGE_SERIALIZER
feature -- Serialization
    serialize (a_msg: PYTHON_MESSAGE): ARRAY [NATURAL_8]
    deserialize (a_bytes: ARRAY [NATURAL_8]): PYTHON_MESSAGE
feature -- Capability
    supports_streaming: BOOLEAN
end
```

Clients don't depend on HTTP-specific serialization; they use MESSAGE_SERIALIZER interface.

---

### 5. Command-Query Separation (CQS)

**Commands** (modify state, no return value):
- `initialize` - Starts server/client, modifies is_initialized state
- `send_message` - Transmits message, modifies last_error if failure
- `shutdown` - Closes connection, modifies is_connected state

**Queries** (return value, no side effects):
- `is_initialized`: BOOLEAN - Query whether initialized
- `is_connected`: BOOLEAN - Query connection status
- `last_error`: detachable STRING_32 - Query error state
- `receive_response`: PYTHON_RESPONSE - Query next response (receives but doesn't send)

**Exception:** Commands that return Current for builder pattern
```eiffel
feature -- Configuration (Command, returns Current for chaining)
    set_timeout (a_ms: INTEGER): like Current
        do
            timeout_ms := a_ms
            Result := Current
        ensure
            timeout_set: timeout_ms = a_ms
            result_current: Result = Current
        end
```

---

### 6. Uniform Access Principle

**Attributes and functions indistinguishable syntactically:**

```eiffel
-- Client code doesn't distinguish between:
msg.timestamp  -- Could be attribute or function
msg.message_id -- Could be attribute or function
msg.is_valid   -- Could be function computing from other fields

-- Implementation detail (encapsulation):
class PYTHON_MESSAGE
    feature
        timestamp: INTEGER_64
            -- Could be stored attribute or computed from created_at field
        message_id: STRING_32
            -- Could be stored or generated on demand
        is_valid: BOOLEAN
            -- Always a function (requires computation)
end
```

Benefit: Can change implementation from attribute to computed property without breaking clients.

---

## Inheritance Hierarchy

### PYTHON_BRIDGE Hierarchy

```
PYTHON_BRIDGE (deferred)
├── HTTP_PYTHON_BRIDGE
│   └── Concrete: HTTP REST API via simple_http + simple_web
├── IPC_PYTHON_BRIDGE
│   └── Concrete: Windows named pipes via simple_ipc
└── GRPC_PYTHON_BRIDGE
    └── Concrete: gRPC RPC via simple_grpc + socket I/O
```

**Hierarchy Justification:**

| Parent | Child | IS-A Valid? | Liskov OK? |
|--------|-------|-------------|-----------|
| PYTHON_BRIDGE | HTTP_PYTHON_BRIDGE | YES - HTTP is a bridge implementation | YES - satisfies bridge contract |
| PYTHON_BRIDGE | IPC_PYTHON_BRIDGE | YES - IPC is a bridge implementation | YES - satisfies bridge contract |
| PYTHON_BRIDGE | GRPC_PYTHON_BRIDGE | YES - gRPC is a bridge implementation | YES - satisfies bridge contract |

---

### PYTHON_MESSAGE Hierarchy

```
PYTHON_MESSAGE (deferred)
├── PYTHON_REQUEST (deferred)
│   ├── HTTP_REQUEST
│   ├── IPC_REQUEST
│   └── GRPC_REQUEST
├── PYTHON_RESPONSE (deferred)
│   ├── HTTP_RESPONSE
│   ├── IPC_RESPONSE
│   └── GRPC_RESPONSE
└── PYTHON_ERROR
    └── (concrete: error is protocol-independent)
```

**Hierarchy Justification:**

| Parent | Child | IS-A Valid? | Liskov OK? |
|--------|-------|-------------|-----------|
| PYTHON_MESSAGE | PYTHON_REQUEST | YES - request is a type of message | YES - message contract satisfied |
| PYTHON_MESSAGE | PYTHON_RESPONSE | YES - response is a type of message | YES - message contract satisfied |
| PYTHON_REQUEST | HTTP_REQUEST | YES - HTTP request is a request | YES - request contract satisfied |
| PYTHON_MESSAGE | PYTHON_ERROR | YES - error is a type of message (special) | YES - error response contract |

---

### MESSAGE_SERIALIZER Hierarchy

```
MESSAGE_SERIALIZER (deferred)
├── HTTP_MESSAGE_SERIALIZER
│   └── Concrete: JSON serialization via simple_json
├── IPC_MESSAGE_SERIALIZER
│   └── Concrete: Binary + length-prefix framing
└── GRPC_MESSAGE_SERIALIZER
    └── Concrete: Protocol Buffers encoding
```

**Hierarchy Justification:**

| Parent | Child | IS-A Valid? | Liskov OK? |
|--------|-------|-------------|-----------|
| MESSAGE_SERIALIZER | HTTP_MESSAGE_SERIALIZER | YES - HTTP serializer is a serializer | YES - serializer contract satisfied |
| MESSAGE_SERIALIZER | IPC_MESSAGE_SERIALIZER | YES - IPC serializer is a serializer | YES - serializer contract satisfied |
| MESSAGE_SERIALIZER | GRPC_MESSAGE_SERIALIZER | YES - gRPC serializer is a serializer | YES - serializer contract satisfied |

---

## Class Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    SIMPLE_PYTHON                            │
│                  (Library Facade)                            │
├─────────────────────────────────────────────────────────────┤
│ + create_http_bridge(): HTTP_PYTHON_BRIDGE                  │
│ + create_ipc_bridge(): IPC_PYTHON_BRIDGE                    │
│ + create_grpc_bridge(): GRPC_PYTHON_BRIDGE                  │
└────────────────────┬────────────────────────────────────────┘
                     │ creates
                     ▼
            ┌────────────────────────┐
            │   PYTHON_BRIDGE        │
            │    (deferred)          │
            ├────────────────────────┤
            │ + initialize           │
            │ + send_message         │
            │ + receive_response     │
            │ + is_initialized: BOOL │
            │ + is_connected: BOOL   │
            │ + shutdown             │
            └────────┬───────────────┘
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│    HTTP_...  │ │    IPC_...   │ │   GRPC_...   │
│   BRIDGE     │ │   BRIDGE     │ │   BRIDGE     │
├──────────────┤ ├──────────────┤ ├──────────────┤
│Uses:         │ │Uses:         │ │Uses:         │
│simple_http   │ │simple_ipc    │ │simple_grpc   │
│simple_web    │ │              │ │socket I/O    │
│simple_json   │ │              │ │              │
└──────────────┘ └──────────────┘ └──────────────┘
      │              │              │
      └──────────────┼──────────────┘
                     │ creates
                     ▼
            ┌────────────────────────┐
            │  PYTHON_MESSAGE        │
            │    (deferred)          │
            ├────────────────────────┤
            │ + message_id: STRING   │
            │ + message_type: STRING │
            │ + timestamp: INT_64    │
            │ + to_bytes(): ARRAY    │
            │ + from_bytes(ARRAY)    │
            │ + is_valid: BOOL       │
            └────────┬───────────────┘
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   REQUEST    │ │  RESPONSE    │ │   ERROR      │
│(deferred)    │ │(deferred)    │ │(concrete)    │
├──────────────┤ ├──────────────┤ ├──────────────┤
│+design_data  │ │+is_valid     │ │+error_code   │
│+rules: ARRAY │ │+errors: ARR  │ │+error_msg    │
└──────────────┘ │+warnings:ARR │ │+error_ctxt   │
                 └──────────────┘ └──────────────┘
```

---

## Composition (Has-A) Relationships

### HTTP_PYTHON_BRIDGE Composition

```
HTTP_PYTHON_BRIDGE
├─ has-a → SIMPLE_HTTP_CLIENT
│   (for sending requests to Python, if bidirectional needed)
├─ has-a → SIMPLE_WEB_SERVER
│   (for receiving requests from Python)
├─ has-a → SIMPLE_JSON_SCHEMA
│   (for validating request/response JSON structure)
└─ has-a → HTTP_MESSAGE_SERIALIZER
    (for JSON serialization/deserialization)
```

**Justification:**
- HTTP_PYTHON_BRIDGE delegates HTTP details to simple_http
- JSON validation to simple_json schema
- Serialization strategy to MESSAGE_SERIALIZER

---

### IPC_PYTHON_BRIDGE Composition

```
IPC_PYTHON_BRIDGE
├─ has-a → SIMPLE_IPC_SERVER
│   (for accepting named pipe connections)
├─ has-a → SIMPLE_IPC_CLIENT (optional)
│   (for bidirectional communication if needed)
└─ has-a → IPC_MESSAGE_SERIALIZER
    (for binary framing serialization)
```

**Justification:**
- IPC_PYTHON_BRIDGE delegates named pipe details to simple_ipc
- Framing logic to serializer

---

### GRPC_PYTHON_BRIDGE Composition

```
GRPC_PYTHON_BRIDGE
├─ has-a → SIMPLE_GRPC_SERVICE
│   (for gRPC protocol layer)
├─ has-a → SOCKET_IO (NEW, pending)
│   (for TCP socket communication)
└─ has-a → GRPC_MESSAGE_SERIALIZER
    (for Protocol Buffers encoding)
```

**Justification:**
- gRPC protocol layer delegated to simple_grpc
- Socket I/O to new library (or ISE wrapper)
- Serialization to MESSAGE_SERIALIZER

---

## Generic Classes (Parameterization)

### Generic Message Types

**Not using generics for Phase 1** - PYTHON_MESSAGE contains STRING_32 payload.

**Future (Phase 2):** Could genericize if customers need typed payloads:

```eiffel
-- Phase 2 consideration (not Phase 1)
generic_class PYTHON_MESSAGE_GENERIC [PAYLOAD_TYPE -> detachable ANY]
    -- Would allow PYTHON_MESSAGE [DESIGN_SPECIFICATION]
    -- But Phase 1 keeps payload as STRING_32 for simplicity
end
```

---

## Facade Pattern: SIMPLE_PYTHON

**Purpose:** Single entry point for library users. Coordinates bridge creation and access.

```eiffel
class SIMPLE_PYTHON
    inherit ANY

feature -- Bridge Creation
    create_http_bridge (a_host: STRING_32; a_port: INTEGER): HTTP_PYTHON_BRIDGE
            -- Create HTTP bridge on specified host:port
        ensure
            bridge_created: Result /= Void
            host_set: Result.host = a_host
            port_set: Result.port = a_port
        end

    create_ipc_bridge (a_pipe_name: STRING_32): IPC_PYTHON_BRIDGE
            -- Create IPC bridge on specified named pipe
        ensure
            bridge_created: Result /= Void
            pipe_set: Result.pipe_name = a_pipe_name
        end

    create_grpc_bridge (a_host: STRING_32; a_port: INTEGER): GRPC_PYTHON_BRIDGE
            -- Create gRPC bridge on specified host:port
        ensure
            bridge_created: Result /= Void
            host_set: Result.host = a_host
            port_set: Result.port = a_port
        end

end
```

**Benefits:**
- Users don't need to know about HTTP_PYTHON_BRIDGE, IPC_PYTHON_BRIDGE, etc.
- Single import: `simple_python.e`
- Creation logic centralized

---

## Builder Pattern: Bridge Configuration

**PYTHON_BRIDGE** supports fluent configuration:

```eiffel
class HTTP_PYTHON_BRIDGE
    inherit PYTHON_BRIDGE

feature -- Configuration (Builder Pattern)
    set_timeout (a_ms: INTEGER): like Current
            -- Set HTTP timeout to a_ms milliseconds
        require
            positive: a_ms > 0
        do
            timeout_ms := a_ms
            Result := Current
        ensure
            timeout_set: timeout_ms = a_ms
            result_current: Result = Current
        end

    set_schema (a_schema: SIMPLE_JSON_SCHEMA): like Current
            -- Set JSON schema for request validation
        do
            json_schema := a_schema
            Result := Current
        ensure
            schema_set: json_schema = a_schema
            result_current: Result = Current
        end

end
```

**Usage:**
```eiffel
bridge := simple_python.create_http_bridge ("localhost", 8080)
    .set_timeout (5000)
    .set_schema (my_schema)
bridge.initialize
```

---

## Strategy Pattern: Message Serialization

**MESSAGE_SERIALIZER** strategy allows protocol-specific serialization without coupling PYTHON_MESSAGE to details:

```eiffel
class HTTP_PYTHON_BRIDGE
    inherit PYTHON_BRIDGE

    feature {NONE}
        serializer: MESSAGE_SERIALIZER
            -- Strategy for JSON serialization

    feature
        send_message (a_request: PYTHON_REQUEST)
            do
                -- Serialize using strategy
                l_bytes := serializer.serialize (a_request)
                -- Send via HTTP
                http_client.post ("/api/validate", l_bytes)
            end

end

class HTTP_MESSAGE_SERIALIZER
    inherit MESSAGE_SERIALIZER

    feature
        serialize (a_msg: PYTHON_MESSAGE): ARRAY [NATURAL_8]
            do
                -- Convert to JSON via simple_json
                l_json := json_converter.to_json (a_msg)
                Result := l_json.to_bytes
            end

end
```

**Benefit:** Change serialization format without changing PYTHON_BRIDGE.

---

## Error Handling: PYTHON_ERROR Class

```eiffel
class PYTHON_ERROR
    inherit PYTHON_MESSAGE

feature
    error_code: INTEGER
            -- Numeric error code (400=client, 500=server)

    error_message: STRING_32
            -- Human-readable error

    error_context: detachable STRING_32
            -- Additional diagnostic info

feature -- Status Queries
    is_retriable: BOOLEAN
            -- Can Python retry this request?
        do
            Result := error_code /= 400  -- Not client errors
        end

    is_client_error: BOOLEAN
            -- Did Python send malformed request?
        do
            Result := error_code = 400
        end

invariant
    valid_code: error_code >= 0
    has_message: error_message /= Void and then error_message.count > 0

end
```

---

## Test Support Architecture

### Test Harness Classes

```eiffel
class TEST_PYTHON_BRIDGE_FIXTURES
        -- Shared setup/teardown for bridge tests

feature
    set_up_http_bridge: HTTP_PYTHON_BRIDGE
            -- Create isolated HTTP test bridge
        do
            create Result.make_default
            Result.set_port (test_port_counter.next)
            Result.initialize
        ensure
            bridge_initialized: Result.is_initialized
        end

    tear_down_bridge (a_bridge: PYTHON_BRIDGE)
            -- Clean up bridge resources
        do
            a_bridge.shutdown
        ensure
            not_connected: not a_bridge.is_connected
        end

end
```

---

## Conclusion: Design Summary

**Key Design Principles Applied:**

1. **Single Responsibility:** Each class has one reason to change
2. **Open/Closed:** New protocols extend PYTHON_BRIDGE without modification
3. **Liskov Substitution:** All bridges interchangeable via interface
4. **Interface Segregation:** Clients depend only on needed features
5. **Command-Query Separation:** Clear distinction between state changes and queries
6. **Uniform Access:** Attributes and functions indistinguishable

**Design Patterns Used:**
- Facade (SIMPLE_PYTHON)
- Strategy (MESSAGE_SERIALIZER)
- Builder (fluent bridge configuration)
- Template Method (PYTHON_BRIDGE deferred interface)

**simple_* Ecosystem Integration:**
- HTTP_PYTHON_BRIDGE uses simple_http, simple_web, simple_json
- IPC_PYTHON_BRIDGE uses simple_ipc
- GRPC_PYTHON_BRIDGE uses simple_grpc (+ socket I/O to be resolved)

**Next Step:** Proceed to Step 5: CONTRACT-DESIGN.md - Define all Design by Contract specifications with MML model queries and frame conditions.

---

End of CLASS-DESIGN.md
