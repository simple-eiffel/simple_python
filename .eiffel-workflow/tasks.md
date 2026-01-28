# Implementation Tasks: simple_python

**Phase:** Phase 4 (Implementation)
**Total Tasks:** 10
**Dependencies:** Linear progression (each task builds on previous)
**Estimated Effort:** 8-12 developer-weeks

---

## Task 1: Message Freeze Mechanism for SCOOP Safety
**Files:** `src/python_message.e`
**Components:** PYTHON_MESSAGE (base class)

### Description
Implement the freeze mechanism that prevents concurrent modification of messages during serialization. This was added in Phase 2 to address SCOOP race conditions.

### Acceptance Criteria
- [x] `is_frozen: BOOLEAN` field exists (initialized False in make)
- [x] `freeze` procedure sets `is_frozen := True`
- [x] `set_attribute` requires `not_frozen: not is_frozen`
- [x] `to_json` requires `is_frozen: is_frozen`
- [x] `to_binary` requires `is_frozen: is_frozen`
- [ ] All contracts compile without errors or warnings
- [ ] Skeletal tests verify freeze behavior (Phase 5)

### Implementation Notes
From approach.md:
- Freeze is a one-way operation (cannot unfreeze)
- Prevents attribute modifications after freeze is called
- Must be called before serialization (to_json/to_binary)
- Enables safe concurrent access in SCOOP context

### Dependencies
- Completes Phase 2 contract work (already done)
- Required before: Task 2, Task 3, Task 4

---

## Task 2: Message Serialization - to_json Implementation
**Files:** `src/python_message.e`, `src/python_validation_request.e`, `src/python_validation_response.e`, `src/python_error.e`
**Components:** Concrete message classes (VALIDATION_REQUEST, VALIDATION_RESPONSE, ERROR)

### Description
Implement to_json for all message subclasses to serialize PYTHON_MESSAGE to SIMPLE_JSON_OBJECT. This is the primary serialization path for all transport protocols.

### Acceptance Criteria
- [ ] to_json creates SIMPLE_JSON_OBJECT
- [ ] JSON includes message_id field (STRING)
- [ ] JSON includes type field (message subclass type)
- [ ] JSON includes timestamp field (ISO-8601 formatted string)
- [ ] JSON includes attributes object with all key-value pairs
- [ ] Concrete subclasses implement to_json (VALIDATION_REQUEST, VALIDATION_RESPONSE, ERROR)
- [ ] Requires message.is_frozen = true (precondition from Phase 2)
- [ ] JSON output validated against SIMPLE_JSON contracts
- [ ] Unit tests verify JSON structure (Phase 5)

### Implementation Notes
From approach.md:
```
Create SIMPLE_JSON_OBJECT
Set "message_id" := STRING to JSON string
Set "type" := message_type (VALIDATION_REQUEST, VALIDATION_RESPONSE, ERROR)
Set "timestamp" := timestamp.date.formatted(...) + "T" + timestamp.time.formatted(...)
Set "attributes" := JSON object from attributes HASH_TABLE
  For each key/value in attributes:
    Set json["attributes"][key] := value.to_json_value()
Return JSON object
```

### Dependencies
- Requires: Task 1 (freeze mechanism)
- Required before: Task 3, Task 5 (HTTP bridge)

---

## Task 3: Message Serialization - to_binary Implementation
**Files:** `src/python_message.e`, concrete message subclasses
**Components:** Concrete message classes (VALIDATION_REQUEST, VALIDATION_RESPONSE, ERROR)

### Description
Implement to_binary for all message subclasses to serialize PYTHON_MESSAGE to 4-byte-prefixed binary format. Used by IPC bridge.

### Acceptance Criteria
- [ ] to_binary returns ARRAY [NATURAL_8]
- [ ] First 4 bytes encode payload length (big-endian)
- [ ] Remaining bytes are JSON serialization from to_json
- [ ] Requires message.is_frozen = true (precondition)
- [ ] Result.count > 4 (postcondition: must include length prefix + payload)
- [ ] Concrete subclasses implement to_binary
- [ ] Unit tests verify binary format (Phase 5)

### Implementation Notes
From approach.md:
```
json_obj := to_json()
json_string := json_obj.to_string()  (UTF-8 encoded)
binary := ARRAY [NATURAL_8] of json_string bytes
Prepend 4-byte length prefix:
  length = binary.count
  frame[0] = (length >> 24) & 0xFF
  frame[1] = (length >> 16) & 0xFF
  frame[2] = (length >> 8) & 0xFF
  frame[3] = length & 0xFF
  Copy binary starting at offset 4
Return frame (with length prefix)
```

### Dependencies
- Requires: Task 1 (freeze), Task 2 (to_json)
- Required before: Task 6 (IPC bridge)

---

## Task 4: IPC Message Framing - encode_frame
**Files:** `src/ipc_python_bridge.e`
**Components:** IPC_PYTHON_BRIDGE.encode_frame

### Description
Implement encode_frame to add 4-byte big-endian length prefix to binary payloads. This enables message framing over named pipes.

### Acceptance Criteria
- [ ] Takes ARRAY [NATURAL_8] payload
- [ ] Returns ARRAY [NATURAL_8] with 4-byte length prefix
- [ ] Result.count = 4 + payload.count
- [ ] First 4 bytes encode payload length (big-endian)
- [ ] Bytes 4..end contain payload unchanged
- [ ] Handles zero-length payloads (result is 4 bytes of zeros)
- [ ] Unit tests verify framing (Phase 5)

### Implementation Notes
From approach.md:
```
Frame format: [4 bytes length (big-endian)] [payload bytes]
length = payload.count
frame = ARRAY [NATURAL_8] of size 4 + payload.count
Write length as big-endian:
  frame[0] = (length >> 24) & 0xFF
  frame[1] = (length >> 16) & 0xFF
  frame[2] = (length >> 8) & 0xFF
  frame[3] = length & 0xFF
Copy payload starting at offset 4
```

### Dependencies
- Requires: None (pure utility)
- Required before: Task 6 (IPC bridge send_message)

---

## Task 5: IPC Message Framing - decode_frame
**Files:** `src/ipc_python_bridge.e`
**Components:** IPC_PYTHON_BRIDGE.decode_frame

### Description
Implement decode_frame to extract payload from 4-byte-prefixed binary frames. Validates frame integrity.

### Acceptance Criteria
- [ ] Takes ARRAY [NATURAL_8] frame
- [ ] Returns detachable ARRAY [NATURAL_8] payload
- [ ] Returns Void if frame.count < 4 (too small)
- [ ] Decodes big-endian length from first 4 bytes
- [ ] Returns Void if payload_length > frame.count - 4 (size mismatch)
- [ ] Returns payload array [4 .. 4 + payload_length]
- [ ] Handles zero-length payloads (returns empty array)
- [ ] Unit tests verify deframing (Phase 5)

### Implementation Notes
From approach.md:
```
Read first 4 bytes as big-endian length:
  payload_length = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]

Verify: payload_length <= frame.count - 4
If mismatch: return Void (size violation)

Extract payload from offset 4 to 4 + payload_length
Return payload array
```

### Dependencies
- Requires: None (pure utility)
- Required before: Task 6 (IPC bridge receive_message)

---

## Task 6: HTTP_PYTHON_BRIDGE - Core Implementation
**Files:** `src/http_python_bridge.e`
**Components:** HTTP_PYTHON_BRIDGE (initialize, close, send_message, receive_message)

### Description
Implement HTTP bridge for REST-based Python-Eiffel communication over HTTP/1.1. Creates HTTP server, handles JSON serialization.

### Acceptance Criteria
- [ ] `initialize`: Creates HTTP server via simple_http on host:port
  - [ ] Binds to configured host and port
  - [ ] Sets up route handler for /validate POST endpoint
  - [ ] Returns true on success, false on failure (with error message)
  - [ ] Postcondition: is_initialized and is_connected on success
  - [ ] Postcondition: has_error set on failure
  - [ ] Postcondition: no_resources_on_failure (not is_connected on failure)

- [ ] `close`: Stops HTTP server and cleans up
  - [ ] Stops accepting new connections
  - [ ] Closes all active client connections
  - [ ] Releases listening socket
  - [ ] Sets is_connected := False
  - [ ] Postcondition: not is_connected

- [ ] `send_message`: Serializes message and sends HTTP response
  - [ ] Calls a_message.freeze before serializing
  - [ ] Calls a_message.to_json to get JSON
  - [ ] Converts JSON to UTF-8 string
  - [ ] Sends HTTP 200 response with JSON body
  - [ ] Tracks bytes_sent (Content-Length + body)
  - [ ] Updates messages_sent counter
  - [ ] Returns true on success, false on failure
  - [ ] Postcondition: failure_implies_error (sets has_error on failure)

- [ ] `receive_message`: Waits for POST request and decodes JSON
  - [ ] Blocks on server socket with timeout_ms
  - [ ] Extracts JSON body from POST request
  - [ ] Validates JSON structure (message_id, type, timestamp, attributes)
  - [ ] Creates appropriate message subclass based on type field
  - [ ] Populates attributes from JSON
  - [ ] Tracks bytes_received (request body size)
  - [ ] Updates messages_received counter
  - [ ] Returns message on success, Void on timeout/error
  - [ ] Sets has_error on timeout or parse failure

- [ ] Performance targets verified: ≤100ms p95, ≥1000 req/sec (Phase 6)
- [ ] Error handling: Connection refused, JSON parse error, timeout, socket errors
- [ ] Unit tests verify bridge lifecycle (Phase 5)

### Implementation Notes
From approach.md - detailed algorithm for each method included above.

### Dependencies
- Requires: Task 2 (to_json), Task 1 (freeze)
- Required before: Task 8 (integration testing)

---

## Task 7: IPC_PYTHON_BRIDGE - Core Implementation
**Files:** `src/ipc_python_bridge.e`
**Components:** IPC_PYTHON_BRIDGE (initialize, close, send_message, receive_message)

### Description
Implement IPC bridge for ultra-low-latency Python-Eiffel communication via Windows named pipes. Uses 4-byte binary framing.

### Acceptance Criteria
- [ ] `initialize`: Creates and opens Windows named pipe
  - [ ] Constructs pipe name: "\\\\.\\pipe\\" + a_pipe_name
  - [ ] Creates named pipe via CreateNamedPipe (Win32 API, inline C)
  - [ ] Sets non-blocking mode with timeout_ms
  - [ ] Returns true on success, false on failure
  - [ ] Postcondition: is_initialized and is_connected on success
  - [ ] Postcondition: has_error set on failure
  - [ ] Postcondition: no_resources_on_failure

- [ ] `close`: Closes named pipe handle
  - [ ] Closes pipe handle via CloseHandle()
  - [ ] Sets is_connected := False
  - [ ] Clears pending_messages queue
  - [ ] Postcondition: not is_connected

- [ ] `send_message`: Serializes message and writes to pipe
  - [ ] Calls a_message.freeze before serializing
  - [ ] Calls a_message.to_binary to get ARRAY [NATURAL_8]
  - [ ] Calls encode_frame to add length prefix
  - [ ] Writes complete frame to named pipe handle
  - [ ] Tracks bytes_sent (4 + payload.count)
  - [ ] Updates messages_sent counter
  - [ ] Returns true on success, false on write failure
  - [ ] Postcondition: failure_implies_error

- [ ] `receive_message`: Reads from pipe and decodes message
  - [ ] Reads exactly 4 bytes from pipe (length prefix, with timeout_ms)
  - [ ] Decodes big-endian length
  - [ ] Reads exactly `length` bytes from pipe (with timeout_ms)
  - [ ] Calls decode_frame to extract payload
  - [ ] Decodes binary payload to PYTHON_MESSAGE subclass
  - [ ] Populates attributes from JSON in payload
  - [ ] Tracks bytes_received (4 + payload.count)
  - [ ] Updates messages_received counter
  - [ ] Returns message on success, Void on timeout/error
  - [ ] Sets has_error on timeout or decode failure

- [ ] Performance targets verified: ≤10ms p95, ≥10,000 msg/sec (Phase 6)
- [ ] Error handling: Pipe creation failed, pipe timeout, malformed frames
- [ ] Unit tests verify bridge lifecycle (Phase 5)

### Implementation Notes
From approach.md - detailed algorithm for each method included above.

### Dependencies
- Requires: Task 3 (to_binary), Task 4 (encode_frame), Task 5 (decode_frame), Task 1 (freeze)
- Required before: Task 8 (integration testing)

---

## Task 8: GRPC_PYTHON_BRIDGE - Skeleton (Phase 2 Future)
**Files:** `src/grpc_python_bridge.e`
**Components:** GRPC_PYTHON_BRIDGE (defer implementation to Phase 2)

### Description
GRPC bridge implementation is deferred to Phase 2. Phase 4 creates skeleton with TODO stubs matching HTTP/IPC pattern.

### Acceptance Criteria
- [ ] Class inherits from PYTHON_BRIDGE
- [ ] All deferred features have TODO Phase 2 Implementation stubs
- [ ] Contracts match HTTP/IPC (initialize, close, send_message, receive_message)
- [ ] Performance target documented: ≤5ms p95, ≥50,000 msg/sec
- [ ] Note: Requires simple_grpc library (Phase 2)
- [ ] Compiles without errors

### Implementation Notes
- Copy HTTP_PYTHON_BRIDGE implementation pattern
- Replace simple_http with simple_grpc (Phase 2)
- Bidirectional streaming for batch validation
- gRPC server bind to host:port

### Dependencies
- Requires: None (skeleton only)
- Deferred until: Phase 2

---

## Task 9: Error Handling and Logging
**Files:** `src/python_bridge.e`, `src/http_python_bridge.e`, `src/ipc_python_bridge.e`
**Components:** Error state management, last_error_message population

### Description
Implement comprehensive error handling to ensure has_error flag and last_error_message are always consistent (Phase 2 critical fix requirement).

### Acceptance Criteria
- [ ] Every operation that can fail sets has_error := true on failure
- [ ] has_error := false only on successful operations
- [ ] last_error_message populated with human-readable error explanation
- [ ] Invariant `error_consistency: has_error = (last_error_message.count > 0)` always true
- [ ] Error messages capture: root cause, operation, context
  - Example: "HTTP server bind failed: Address already in use (port 8080)"
- [ ] Errors categorized: connection, timeout, format, resource exhaustion
- [ ] Unit tests verify error semantics (Phase 5)

### Implementation Notes
From Phase 2 Critical Fix #1:
```eiffel
failure_implies_error: (not Result) implies has_error
error_message_set: has_error implies (last_error_message.count > 0)
```

### Dependencies
- Requires: Task 6 (HTTP), Task 7 (IPC) implementations
- Required before: Task 8 (integration testing)

---

## Task 10: Integration and Acceptance Testing Preparation
**Files:** Test classes (Phase 5 work), but Phase 4 ensures contracts are testable
**Components:** Documentation of test scenarios

### Description
Phase 4 ensures all contracts are implemented and testable. Phase 5 will flesh out tests based on these contracts. This task documents what Phase 5 needs to verify.

### Acceptance Criteria
- [ ] HTTP bridge can be created, initialized, send message, receive message, closed
- [ ] IPC bridge can be created, initialized, send message, receive message, closed
- [ ] Message freeze mechanism prevents modification after freeze
- [ ] Error semantics: failed operations set has_error and last_error_message
- [ ] Resource cleanup: failed initialize leaves no held resources
- [ ] Frame encoding/decoding: payloads correctly framed with 4-byte prefix
- [ ] No runtime exceptions (all error paths handled gracefully)
- [ ] Compilation: System Recompiled with ZERO WARNINGS

### Implementation Notes
From Phase 1: Skeletal tests exist in test/*.e
Phase 5 will flesh out with real assertions and contract verification

### Dependencies
- Requires: Tasks 1-9 (all implementation complete)
- Signals: Transition to Phase 5 (Verification)

---

## Task Dependency Graph

```
Task 1 (Freeze)
  └─> Task 2 (to_json) ─┐
  └─> Task 3 (to_binary) ┤─> Task 6 (HTTP) ─┐
                         ├─> Task 7 (IPC) ──┼─> Task 9 (Error Handling)
                         │                  └─> Task 10 (Integration)
       Task 4 (encode_frame) ─┐
       Task 5 (decode_frame) ─┴─> Task 7 (IPC)

Task 8 (gRPC) - Deferred to Phase 2
```

## Critical Path

**Longest chain:** Task 1 → Task 3 → Task 7 → Task 9 → Task 10
**Estimated timeline:** 8-12 weeks (includes Phase 5 testing, Phase 6 hardening)

## Phase Transitions

- **Phase 4 (Implementation):** Tasks 1-10 write feature bodies
- **Phase 5 (Verification):** Flesh out tests, verify contracts, measure coverage
- **Phase 6 (Hardening):** Adversarial tests, stress tests, SCOOP safety
- **Phase 7 (Ship):** Documentation, binaries, production release

---

## Notes for Implementer (Phase 4)

### Key Constraints
1. **Contracts are FROZEN** - Do not modify require/ensure/invariant clauses
2. **ZERO WARNINGS POLICY** - Any compiler warnings must be fixed immediately
3. **Preconditions must be satisfied** - to_json/to_binary require is_frozen
4. **Error consistency** - Every failure must set has_error and last_error_message
5. **Resource cleanup** - Failed operations must not leak resources

### Code Organization
- Implementation in `src/*.e` (same files as contracts)
- Feature bodies replace TODO Phase 4 Implementation stubs
- Tests remain in `test/*.e` (fleshed out in Phase 5)
- No new classes (architecture from Phase 1 is final)

### Dependencies to Manage
- simple_http: HTTP server library (HTTP bridge)
- simple_json: JSON serialization (all message types)
- Win32 API via inline C: CreateNamedPipe, CloseHandle (IPC bridge)
- DATE_TIME: Message timestamp (already imported)

### Testing Approach
- Phase 4: Compile and verify no syntax errors
- Phase 5: Run skeletal tests, flesh out with full assertions
- Phase 6: Adversarial testing and SCOOP verification

---

**Phase 3 Status:** COMPLETE ✓
