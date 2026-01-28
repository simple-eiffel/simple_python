# DOMAIN MODEL: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Specification Phase:** Step 2 - Domain Concepts and Class Structure

---

## Domain Overview

The simple_python library operates at the intersection of three key domains:

1. **Eiffel Validation Domain** - High-assurance verification of electronic designs using Design by Contract
2. **Message Transport Domain** - Protocol-independent communication semantics (HTTP, IPC, gRPC)
3. **Manufacturing Validation Domain** - Control board and embedded system verification with compliance tracking

This specification identifies domain concepts that become classes, defines their relationships, and documents domain rules that enforce constraints.

---

## Domain Concepts

### Concept 1: PYTHON_BRIDGE (Bridge Interface)

**Definition:** The abstraction that represents a communication channel between Eiffel and Python systems. Each bridge (HTTP, IPC, gRPC) implements this interface with protocol-specific behavior while sharing common semantics.

**Why it exists:**
- Manufacturing customers deploy to different environments (cloud, local machine, distributed)
- Single bridge interface allows code reuse across three protocol implementations
- PYTHON_BRIDGE deferred interface defines contract ALL implementations must satisfy

**Attributes:**
- `is_initialized`: boolean - Whether bridge is ready
- `is_connected`: boolean - Whether connection is active
- `last_error`: detachable STRING_32 - Error state tracking

**Behaviors:**
- `initialize` - Set up protocol-specific server/client
- `send_message` - Transmit request to Python
- `receive_response` - Await Python response
- `shutdown` - Close connection, release resources

**Related to:**
- PYTHON_MESSAGE (messages communicated via bridge)
- HTTP_PYTHON_BRIDGE, IPC_PYTHON_BRIDGE, GRPC_PYTHON_BRIDGE (concrete implementations)

**Will become:** Deferred class `PYTHON_BRIDGE` with contracts defining send/receive semantics

---

### Concept 2: PYTHON_MESSAGE (Protocol-Agnostic Message)

**Definition:** Base abstraction representing any message that can be transmitted via the bridge. Encapsulates payload, metadata, and protocol-independent serialization contract.

**Why it exists:**
- All three protocols (HTTP, IPC, gRPC) exchange messages but with different serialization formats
- Deferred PYTHON_MESSAGE allows protocol-specific subclasses to implement to_bytes/from_bytes
- Message contracts ensure data integrity regardless of transport layer

**Attributes:**
- `message_id`: STRING_32 - Unique identifier (UUID format)
- `message_type`: STRING_32 - "validate_request", "error_response", etc.
- `payload`: detachable PYTHON_PAYLOAD - Protocol-agnostic data container
- `timestamp`: INTEGER_64 - Unix timestamp (microseconds for precision)
- `compliance_metadata`: detachable MANUFACTURING_METADATA - Manufacturing audit trail

**Behaviors:**
- `to_bytes`: ARRAY [NATURAL_8] - Serialize to protocol-specific format
- `from_bytes` - Deserialize from protocol-specific format
- `is_valid`: BOOLEAN - Structural validation (has required fields)

**Related to:**
- PYTHON_REQUEST, PYTHON_RESPONSE (semantically-typed messages)
- PYTHON_ERROR (error responses)
- HTTP_MESSAGE, IPC_MESSAGE, GRPC_MESSAGE (protocol-specific implementations)

**Will become:** Deferred class `PYTHON_MESSAGE` with serialization contracts and MML model queries

---

### Concept 3: PYTHON_REQUEST (Request Message)

**Definition:** A message representing a validation request sent from Python to Eiffel. Contains design data and validation rules.

**Why it exists:**
- Distinguishes request intent from response intent semantically
- Manufacturing customers need request traceability for compliance
- Request contracts enforce valid data structure before Eiffel processes

**Attributes:**
- Inherits from PYTHON_MESSAGE: message_id, message_type, timestamp, compliance_metadata
- `design_data`: STRING_32 - The design/code/configuration to validate
- `validation_rules`: ARRAY [STRING_32] - List of rule identifiers to apply
- `priority`: INTEGER - Request priority (1=high, 10=low)
- `correlation_id`: STRING_32 - Links to related validation requests

**Behaviors:**
- Inherits to_bytes/from_bytes for protocol-specific serialization
- Implements is_valid with stronger preconditions:
  - design_data not empty
  - validation_rules non-Void
  - correlation_id well-formed UUID

**Related to:**
- PYTHON_VALIDATION_REQUEST (HTTP-specific subclass)
- IPC_VALIDATION_REQUEST (IPC-specific subclass)
- GRPC_VALIDATION_REQUEST (Protocol Buffers wrapper)
- MANUFACTURING_METADATA (compliance metadata attached)

**Will become:** Deferred class `PYTHON_REQUEST` extending `PYTHON_MESSAGE`

---

### Concept 4: PYTHON_RESPONSE (Response Message)

**Definition:** A message representing validation results returned from Eiffel to Python. Contains success status, errors, warnings, and metadata.

**Why it exists:**
- Semantically distinct from request (doesn't conflate query with answer)
- Response contracts guarantee that errors and warnings are mutually consistent
- Manufacturing customers need complete validation evidence

**Attributes:**
- Inherits from PYTHON_MESSAGE: message_id, message_type, timestamp
- `is_valid`: BOOLEAN - Validation passed (true) or failed (false)
- `errors`: ARRAY [STRING_32] - List of validation failures
- `warnings`: ARRAY [STRING_32] - Non-critical issues
- `evidence_url`: detachable STRING_32 - URL to stored validation evidence
- `validation_duration_ms`: INTEGER - How long validation took

**Behaviors:**
- Implements invariant: `is_valid xor errors.count > 0` (valid XOR errors, never both)
- Postcondition frames: warnings unchanged if no validation changes
- Inherits serialization contracts

**Related to:**
- PYTHON_RESPONSE_DATA (inner data structure)
- MANUFACTURING_COMPLIANCE_RESULT (compliance-specific responses)

**Will become:** Concrete class `PYTHON_RESPONSE` with invariant enforcement

---

### Concept 5: PYTHON_ERROR (Error Representation)

**Definition:** Standard error information returned when Eiffel cannot fulfill a request (malformed input, internal error, timeout).

**Why it exists:**
- Separate error responses from validation failures
- Python client distinguishes "validation failed" (design is invalid) from "request failed" (bridge error)
- Manufacturing requires error categorization for audit trails

**Attributes:**
- `error_code`: INTEGER - Numeric code (400=client error, 500=server error, 503=timeout)
- `error_message`: STRING_32 - Human-readable error description
- `error_context`: detachable STRING_32 - Additional diagnostic information

**Behaviors:**
- `is_retriable`: BOOLEAN - Can Python retry this request?
- `is_client_error`: BOOLEAN - Did Python send malformed request?

**Related to:**
- PYTHON_RESPONSE (can contain error instead of validation results)
- HTTP_ERROR_RESPONSE (HTTP status codes)
- IPC_ERROR_RESPONSE (IPC-specific error frames)

**Will become:** Class `PYTHON_ERROR` with error categorization

---

### Concept 6: HTTP_PYTHON_BRIDGE (HTTP Protocol Implementation)

**Definition:** Concrete implementation of PYTHON_BRIDGE using REST API over HTTP. Python uses simple_http client library; Eiffel hosts simple_web server.

**Why it exists:**
- 80% of manufacturing integrations use HTTP REST
- simple_http and simple_json are production-proven in ecosystem
- RESTful API matches industry standards

**Attributes:**
- Inherits from PYTHON_BRIDGE
- `server_host`: STRING_32 - Hostname (default: localhost)
- `server_port`: INTEGER - TCP port (default: 8080)
- `json_schema`: detachable SIMPLE_JSON_SCHEMA - Schema for request/response validation
- `timeout_ms`: INTEGER - HTTP request timeout (default: 5000)

**Behaviors:**
- `initialize` - Starts simple_web HTTP server on port, registers routes
- `send_message` - HTTP POST to /api/validate with JSON payload (via simple_http client)
- `receive_response` - Parse HTTP 200 JSON response
- Error handling: Maps HTTP status codes (400=client error, 500=server error)
- Retry logic: Exponential backoff on transient failures

**Related to:**
- SIMPLE_HTTP_CLIENT (simple_* ecosystem library)
- SIMPLE_WEB_SERVER (simple_* ecosystem library)
- SIMPLE_JSON_SCHEMA (simple_* ecosystem library)
- PYTHON_BRIDGE (interface it implements)
- PYTHON_MESSAGE (JSON serialization)

**Will become:** Concrete class `HTTP_PYTHON_BRIDGE` implementing `PYTHON_BRIDGE`

---

### Concept 7: IPC_PYTHON_BRIDGE (Named Pipes IPC Implementation)

**Definition:** Concrete implementation of PYTHON_BRIDGE using Windows named pipes. Ultra-low latency for same-machine validation. Uses simple_ipc from simple_* ecosystem.

**Why it exists:**
- Manufacturing embedded systems require <5ms latency for real-time feedback
- Named pipes (Windows) eliminate network overhead
- simple_ipc handles Windows IPC platform details

**Attributes:**
- Inherits from PYTHON_BRIDGE
- `pipe_name`: STRING_32 - Named pipe name (default: \\.\pipe\eiffel_validator)
- `max_message_size`: INTEGER - Max bytes per message (default: 1MB)
- `frame_header_size`: INTEGER - Length of length-prefix (always 4 bytes)

**Behaviors:**
- `initialize` - Create named pipe server listening on pipe_name
- `send_message` - Frame message with 4-byte length prefix, write to pipe
- `receive_response` - Read 4-byte length, read payload, parse response
- Error recovery: Reconnect if pipe breaks (partial transmission)
- Bidirectional streaming: Full-duplex communication

**Related to:**
- SIMPLE_IPC (simple_* ecosystem library for named pipes)
- PYTHON_BRIDGE (interface it implements)
- PYTHON_MESSAGE (binary serialization for IPC)

**Will become:** Concrete class `IPC_PYTHON_BRIDGE` implementing `PYTHON_BRIDGE`

---

### Concept 8: GRPC_PYTHON_BRIDGE (gRPC RPC Implementation)

**Definition:** Concrete implementation of PYTHON_BRIDGE using gRPC with Protocol Buffers. Enables distributed validation across network with type-safe RPC and streaming support.

**Why it exists:**
- Cloud deployments require distributed RPC (not same-machine)
- gRPC standardized protocol in distributed systems
- simple_grpc provides protocol layer; socket I/O integration pending

**Attributes:**
- Inherits from PYTHON_BRIDGE
- `grpc_host`: STRING_32 - Listen address (default: 0.0.0.0)
- `grpc_port`: INTEGER - TCP port (default: 50051)
- `protobuf_descriptors`: detachable PROTOBUF_DESCRIPTOR_SET - Message schema
- `max_concurrent_streams`: INTEGER - Max parallel RPCs (default: 100)

**Behaviors:**
- `initialize` - Start gRPC server, register service endpoints
- `send_message` - Encode to Protocol Buffers, transmit via gRPC
- `receive_response` - Receive and decode Protocol Buffers response
- Streaming: Supports unary, server-streaming, client-streaming, bidirectional
- Error handling: gRPC status codes (OK, CANCELLED, UNKNOWN, INVALID_ARGUMENT, DEADLINE_EXCEEDED)

**Related to:**
- SIMPLE_GRPC (simple_* ecosystem library for gRPC protocol layer)
- SOCKET_IO (NEW REQUIREMENT - TCP sockets for Eiffel, not yet in simple_* ecosystem)
- PYTHON_BRIDGE (interface it implements)
- PROTOBUF_MESSAGE (Protocol Buffers serialization)

**Will become:** Concrete class `GRPC_PYTHON_BRIDGE` implementing `PYTHON_BRIDGE`

---

### Concept 9: MANUFACTURING_METADATA (Compliance Audit Trail)

**Definition:** Optional metadata attached to messages for compliance with manufacturing standards (IEC 61131, ISO 26262, IEC 62304). Enables audit trail linking validation to requirements and test cases.

**Why it exists:**
- Manufacturing regulations require traceability: which requirement was tested, by whom, when, what was the result
- simple_python must support compliance frameworks from Day 1
- Phase 1 includes metadata fields; Phase 2 implements full framework

**Attributes:**
- `requirement_id`: detachable STRING_32 - Requirement being tested (e.g., "REQ-2.3.1")
- `test_case_id`: detachable STRING_32 - Test case identifier
- `operator_id`: detachable STRING_32 - Who ran validation
- `compliance_standard`: detachable STRING_32 - "IEC-61131-3" or "ISO-26262" or "IEC-62304"
- `evidence_artifact_url`: detachable STRING_32 - Where validation evidence stored
- `validation_timestamp`: INTEGER_64 - When validation executed

**Behaviors:**
- `is_complete`: BOOLEAN - All required fields populated?
- `is_traceable`: BOOLEAN - Can this validation be audited?

**Related to:**
- PYTHON_MESSAGE (messages can have manufacturing metadata)
- PYTHON_REQUEST (requests declare which requirements being tested)
- PYTHON_RESPONSE (responses capture evidence for audit)

**Will become:** Class `MANUFACTURING_METADATA` with audit trail contracts

---

### Concept 10: MESSAGE_SERIALIZER (Protocol-Specific Serialization)

**Definition:** Strategy object that converts PYTHON_MESSAGE to/from protocol-specific byte representation. Separates serialization logic from message semantics.

**Why it exists:**
- HTTP uses JSON via simple_json (text-based, schema-validated)
- IPC uses length-prefix binary framing (compact, fast)
- gRPC uses Protocol Buffers (type-safe, compact)
- Single MESSAGE_SERIALIZER interface allows protocol-agnostic message code

**Attributes:**
- (strategy pattern - no attributes)

**Behaviors:**
- `serialize (a_message: PYTHON_MESSAGE): ARRAY [NATURAL_8]` - Convert to bytes
- `deserialize (a_bytes: ARRAY [NATURAL_8]): PYTHON_MESSAGE` - Restore from bytes
- `supports_streaming`: BOOLEAN - Does this protocol support streaming?

**Related to:**
- PYTHON_MESSAGE (messages to be serialized)
- HTTP_MESSAGE_SERIALIZER (JSON serialization)
- IPC_MESSAGE_SERIALIZER (binary framing)
- GRPC_MESSAGE_SERIALIZER (Protocol Buffers)

**Will become:** Deferred class `MESSAGE_SERIALIZER` with serialization contracts

---

## Concept Relationships

### Inheritance Hierarchy

```
PYTHON_BRIDGE (deferred)
├── HTTP_PYTHON_BRIDGE (REST/JSON)
├── IPC_PYTHON_BRIDGE (Named pipes)
└── GRPC_PYTHON_BRIDGE (Protocol Buffers + HTTP/2)

PYTHON_MESSAGE (deferred)
├── PYTHON_REQUEST (request intent)
├── PYTHON_RESPONSE (response intent)
└── PYTHON_ERROR (error state)

MESSAGE_SERIALIZER (deferred)
├── HTTP_MESSAGE_SERIALIZER
├── IPC_MESSAGE_SERIALIZER
└── GRPC_MESSAGE_SERIALIZER
```

### Composition Relationships

```
HTTP_PYTHON_BRIDGE
  ├─ has-a → SIMPLE_HTTP_CLIENT (from simple_http)
  ├─ has-a → SIMPLE_WEB_SERVER (from simple_web)
  ├─ has-a → SIMPLE_JSON_SCHEMA (from simple_json)
  └─ has-a → HTTP_MESSAGE_SERIALIZER

IPC_PYTHON_BRIDGE
  ├─ has-a → SIMPLE_IPC_SERVER (from simple_ipc)
  ├─ has-a → SIMPLE_IPC_CLIENT (from simple_ipc)
  └─ has-a → IPC_MESSAGE_SERIALIZER

GRPC_PYTHON_BRIDGE
  ├─ has-a → SIMPLE_GRPC_SERVICE (from simple_grpc)
  ├─ has-a → SOCKET_IO (NEW - TCP sockets)
  └─ has-a → GRPC_MESSAGE_SERIALIZER

PYTHON_MESSAGE
  ├─ has-a → MESSAGE_SERIALIZER (strategy)
  └─ may-have → MANUFACTURING_METADATA (optional audit trail)

PYTHON_REQUEST
  └─ has-a → MANUFACTURING_METADATA (which requirement, test case)

PYTHON_RESPONSE
  ├─ has-a → MANUFACTURING_METADATA (where evidence stored)
  └─ may-contain → PYTHON_ERROR (when validation fails)
```

### Aggregation ("uses") Relationships

```
HTTP_PYTHON_BRIDGE
  uses-library → simple_http (MUST from simple_* ecosystem)
  uses-library → simple_web (MUST from simple_* ecosystem)
  uses-library → simple_json (MUST from simple_* ecosystem)

IPC_PYTHON_BRIDGE
  uses-library → simple_ipc (MUST from simple_* ecosystem)

GRPC_PYTHON_BRIDGE
  uses-library → simple_grpc (MUST from simple_* ecosystem)
  requires-library → Socket I/O (PENDING - evaluate options)

All bridges
  may-use → simple_logger (OPTIONAL - for diagnostics)
  may-use → simple_mml (OPTIONAL - for MML model queries in contracts)
```

---

## Domain Rules

### Rule DR-001: Bridge Interface Contract Invariance

**Statement:** All implementations of PYTHON_BRIDGE must satisfy identical preconditions and postconditions, regardless of protocol.

**Enforcement:** Eiffel's contract inheritance - derived classes can strengthen preconditions (require fewer), weaken postconditions (ensure less), but contracts are inherited and checked.

**Implication:** Code using PYTHON_BRIDGE polymorphically relies on contract uniformity.

---

### Rule DR-002: Message Serialization Completeness

**Statement:** Every PYTHON_MESSAGE subclass must implement both `to_bytes` and `from_bytes`. Serialization must be lossless (deserialize(serialize(m)) = m).

**Enforcement:** Deferred features in PYTHON_MESSAGE require implementation; postcondition on from_bytes enforces that deserialized message has same message_id as original.

**Implication:** Protocol switching is transparent to message semantics.

---

### Rule DR-003: Response Validity Invariant

**Statement:** A PYTHON_RESPONSE is either valid (is_valid = true, errors.count = 0) OR invalid (is_valid = false, errors.count > 0), never both.

**Enforcement:** Invariant: `is_valid xor (errors.count > 0)`

**Implication:** Python client can reliably check `if response.is_valid then` without checking errors.

---

### Rule DR-004: Manufacturing Metadata Immutability

**Statement:** Once MANUFACTURING_METADATA is attached to a message, it cannot be modified. This preserves audit trail integrity.

**Enforcement:** MANUFACTURING_METADATA attributes are set-once in creation; no assignment features after initialization.

**Implication:** Compliance evidence cannot be tampered with post-validation.

---

### Rule DR-005: simple_* Ecosystem First

**Statement:** All external dependencies must use simple_* libraries from the Eiffel ecosystem where available. ISE libraries only for fundamentals (base, testing) that have no simple_* equivalent.

**Enforcement:** ECF configuration; no `$ISE_LIBRARY` references except whitelisted base, testing.

**Implication:** simple_python contributes to ecosystem growth and depends only on proven simple_* libraries.

**Allowed ISE Libraries:**
- `base` (fundamental types: ARRAY, STRING, INTEGER, etc.)
- `testing` (EQA_TEST_SET - standard test framework)

**Preferred simple_* Libraries:**
- `simple_datetime` (DATE, TIME, DATE_TIME - from simple_* ecosystem)

**Forbidden ISE Libraries (simple_* alternatives exist):**
- ❌ `$ISE_LIBRARY/library/process` → ✅ Use simple_process
- ❌ `$ISE_LIBRARY/library/net` → ✅ Use simple_http
- ❌ `$ISE_LIBRARY/library/web` → ✅ Use simple_web
- ❌ `$ISE_LIBRARY/library/json` → ✅ Use simple_json
- ❌ `$GOBO/library/regexp` → ✅ Use simple_regex
- ❌ `$GOBO/library/string` → ✅ Use simple_encoding

---

### Rule DR-006: SCOOP Concurrency Safety

**Statement:** All classes must be SCOOP-compatible. No explicit locks, no mutable shared state without `separate` keyword.

**Enforcement:** ECF configuration `<concurrency support="scoop"/>` and void_safety="all".

**Implication:** Multiple Python clients can call different bridge instances concurrently without data races.

---

### Rule DR-007: Void Safety

**Statement:** All code is void-safe. No attribute or argument can be Void unless explicitly marked `detachable`.

**Enforcement:** ECF configuration `<void_safety support="all"/>`.

**Implication:** Null pointer exceptions prevented at compile time.

---

### Rule DR-008: Protocol Independence

**Statement:** Core PYTHON_BRIDGE, PYTHON_MESSAGE, PYTHON_REQUEST, PYTHON_RESPONSE classes define semantics independent of protocol. Protocol-specific details isolated in HTTP_*, IPC_*, GRPC_* classes.

**Enforcement:** Deferred interfaces and protocol-specific subclasses enforce separation.

**Implication:** Bug fixes in message validation benefit all three protocols.

---

## Domain Glossary

| Term | Definition | Context |
|------|-----------|---------|
| **Bridge** | Communication channel between Eiffel and Python | Message transport domain |
| **Message** | Unit of communication (request, response, error) | Message semantics domain |
| **Protocol** | Transport mechanism (HTTP, IPC, gRPC) | Transport layer |
| **Serialization** | Conversion between Eiffel objects and bytes | Protocol boundary |
| **Validation Request** | Command to validate a design or code snippet | Manufacturing domain |
| **Validation Response** | Results of validation (pass/fail + errors) | Manufacturing domain |
| **Manufacturing Metadata** | Audit trail information (requirement, test case, operator) | Compliance domain |
| **Compliance Standard** | Regulatory framework (IEC 61131, ISO 26262, IEC 62304) | Manufacturing domain |
| **Evidence Artifact** | Stored validation result for regulatory audit | Compliance domain |
| **simple_* Ecosystem** | Collection of 100+ production Eiffel libraries following unified standards | Ecosystem domain |
| **SCOOP** | Simple Concurrent Object-Oriented Programming (Eiffel concurrency) | Concurrency domain |
| **DBC** | Design by Contract (preconditions, postconditions, invariants) | Eiffel paradigm |
| **Void Safe** | Type system where Void (null) is explicit, not implicit | Eiffel paradigm |
| **Named Pipes** | Windows IPC mechanism for same-machine communication | IPC protocol |
| **Protocol Buffers** | Google's serialization format for gRPC | gRPC protocol |
| **Frame** | Protocol-level message unit (HTTP request/response, IPC length+payload, gRPC frame) | Message framing |

---

## Domain Use Cases (Mapped to Classes)

### UC-001: HTTP Cloud Validation

**Entities involved:**
1. PYTHON_REQUEST - Client constructs validation request
2. HTTP_PYTHON_BRIDGE - Server receives, routes request
3. MESSAGE_SERIALIZER (HTTP variant) - Deserializes JSON
4. PYTHON_RESPONSE - Server constructs response with validation results
5. MANUFACTURING_METADATA - Optional audit trail attachment
6. simple_http, simple_web, simple_json - Transport layer

**Data flow:**
```
Python HTTP Client
  → serialize to JSON via simple_json
  → POST via simple_http
  → HTTP_PYTHON_BRIDGE (simple_web server)
    → deserialize JSON
    → construct PYTHON_REQUEST
    → execute Eiffel validation logic
    → construct PYTHON_RESPONSE
    → serialize to JSON
  ← HTTP 200 + JSON response
  → deserialize JSON via simple_json
  → PYTHON_RESPONSE object
```

---

### UC-002: IPC Real-Time Validation

**Entities involved:**
1. PYTHON_REQUEST - Client constructs request
2. IPC_PYTHON_BRIDGE - Server listens on named pipe
3. MESSAGE_SERIALIZER (IPC variant) - Binary framing
4. PYTHON_RESPONSE - Server constructs response
5. simple_ipc - IPC protocol
6. MANUFACTURING_METADATA - Compliance metadata

**Data flow:**
```
Python Named Pipe Client
  → serialize via IPC_MESSAGE_SERIALIZER
  → frame: [4-byte length][binary payload]
  → write to \\.\pipe\eiffel_validator via simple_ipc
  → IPC_PYTHON_BRIDGE (simple_ipc server)
    → read frame (4-byte length)
    → read payload bytes
    → deserialize binary
    → construct PYTHON_REQUEST
    → execute Eiffel validation
    → construct PYTHON_RESPONSE
    → serialize binary, frame
  ← write to pipe
  → read response frame
  → deserialize binary
  → PYTHON_RESPONSE object
```

---

### UC-003: gRPC Distributed Validation

**Entities involved:**
1. PYTHON_REQUEST - Client constructs request
2. GRPC_PYTHON_BRIDGE - Server listens on TCP port
3. MESSAGE_SERIALIZER (gRPC variant) - Protocol Buffers
4. PYTHON_RESPONSE - Server constructs response
5. simple_grpc - gRPC protocol layer
6. Socket I/O - TCP transmission (NEW REQUIREMENT)

**Data flow:**
```
Python gRPC Client
  → construct ValidateRequest protobuf
  → send via grpcio (gRPC library)
  → TCP transmission (via Socket I/O)
  → GRPC_PYTHON_BRIDGE (Socket I/O server)
    → receive gRPC frame
    → decode Protocol Buffers
    → construct PYTHON_REQUEST
    → execute Eiffel validation
    → construct PYTHON_RESPONSE
    → encode Protocol Buffers
    → frame as gRPC response
  ← TCP transmission
  → receive gRPC response
  → decode Protocol Buffers via grpcio
  → ValidateResponse protobuf object
```

---

## Next Steps

Proceed to Step 3: CHALLENGED-ASSUMPTIONS.md - Question every assumption from research phase and identify missing requirements or design gaps.

---

End of DOMAIN-MODEL.md
