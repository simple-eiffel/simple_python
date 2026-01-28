# Implementation Approach: simple_python

## Overview

This document sketches the implementation strategy for the Eiffel-Python bridge library, which provides three transport protocols for validation communication between Python orchestration systems and Eiffel manufacturing validators.

## Phase 1: HTTP and IPC Bridges

### 1. HTTP_PYTHON_BRIDGE Implementation

**Transport:** HTTP/1.1 JSON over TCP/IP

**Algorithm:**
1. `initialize`: Create and bind HTTP server to host:port using simple_http library
   - Parse host/port configuration
   - Create HTTP server instance with route handler for /validate
   - Bind to configured address with timeout_ms
   - Return true on success, set error message on failure

2. `send_message`: Serialize PYTHON_MESSAGE to JSON, send HTTP response
   - Call `a_message.to_json()` to get SIMPLE_JSON_OBJECT
   - Convert JSON object to UTF-8 string
   - Send HTTP 200 response with JSON body
   - Track bytes_sent (Content-Length header + body)
   - Update messages_sent counter
   - Return true on success, false on error (capture in last_error_message)

3. `receive_message`: Wait for HTTP POST request, decode JSON to PYTHON_MESSAGE
   - Block on server socket with timeout_ms
   - Extract JSON body from POST request
   - Validate JSON structure (must have message_id, type, timestamp, attributes)
   - Create appropriate message subclass (PYTHON_VALIDATION_REQUEST, PYTHON_VALIDATION_RESPONSE, PYTHON_ERROR)
   - Populate attributes from JSON
   - Track bytes_received (request body size)
   - Update messages_received counter
   - Return Void on timeout or decode error (set has_error)

4. `close`: Shutdown HTTP server and release resources
   - Stop accepting new connections
   - Close all active client connections
   - Release listening socket
   - Set is_connected := False

**Error Handling:**
- Connection refused → has_error := true, last_error_message := "Connection refused"
- JSON parse error → Return Void, set error
- Request timeout → Return Void, set error
- Socket write error → Return false, set error

### 2. IPC_PYTHON_BRIDGE Implementation

**Transport:** Windows named pipes (\\.\\pipe\\name) with binary framing

**Algorithm:**

1. `encode_frame`: Add 4-byte big-endian length prefix to payload
   ```
   Frame format: [4 bytes length (big-endian)] [payload bytes]

   length = payload.count
   frame = ARRAY [NATURAL_8] of size 4 + payload.count
   Write length as big-endian: (length >> 24) & 0xFF, (length >> 16) & 0xFF, etc.
   Copy payload starting at offset 4
   ```

2. `decode_frame`: Extract payload from frame, validate length
   ```
   Read first 4 bytes as big-endian length
   payload_length = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]

   Verify: payload_length <= frame.count - 4
   If mismatch: return Void (size violation)

   Extract payload from offset 4 to 4 + payload_length
   Return payload array
   ```

3. `initialize`: Create and open Windows named pipe in listening mode
   - Construct pipe name: "\\\\.\\pipe\\" + a_pipe_name
   - Create named pipe handle using CreateNamedPipe (Win32 API via inline C)
   - Set non-blocking mode with timeout_ms
   - Set is_initialized := true on success
   - Set has_error + last_error_message on failure (GetLastError())

4. `send_message`: Serialize message, add length prefix, write to pipe
   - Call `a_message.to_binary()` to get ARRAY [NATURAL_8]
   - Call `encode_frame(payload)` to add length prefix
   - Write complete frame to named pipe handle
   - Track bytes_sent (4 + payload.count)
   - Update messages_sent counter
   - Return true on success, false on write failure
   - Capture error via GetLastError()

5. `receive_message`: Read length prefix, read payload, decode message
   - Read exactly 4 bytes from pipe (with timeout_ms)
   - Decode big-endian length
   - Read exactly `length` bytes from pipe (with timeout_ms)
   - Call `decode_frame()` to extract payload
   - Decode binary payload to PYTHON_MESSAGE (call appropriate subclass constructor with binary data)
   - Track bytes_received (4 + payload.count)
   - Update messages_received counter
   - Return message on success, Void on error
   - Handle pipe timeout: return Void, set has_error

6. `close`: Close named pipe handle and disconnect
   - If pipe handle is open: CloseHandle() (Win32 API)
   - Set is_connected := False
   - Clear any pending messages

**Error Handling:**
- Pipe creation failed (ERR_PIPE_BUSY) → Retry with timeout or fail
- Pipe timeout (ERROR_OPERATION_ABORTED) → Return Void, set error
- Write to closed pipe → Return false, set error
- Frame size mismatch (decoded length != remaining bytes) → Return Void

### 3. Message Serialization (Phase 4)

**to_json() Implementation:**
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

**to_binary() Implementation:**
```
json_obj := to_json()
json_string := json_obj.to_string()  (UTF-8 encoded)
binary := ARRAY [NATURAL_8] of json_string bytes
Prepend 4-byte length prefix via encode_frame()
Return frame (with length prefix)
```

## Phase 2: gRPC Bridge (Future)

**Deferred to Phase 2:**
- gRPC server implementation via simple_grpc (when available)
- Bidirectional streaming for batch validation
- Performance target: ≤5ms p95, ≥50,000 msg/sec
- Linux platform support

## Testing Strategy

### Phase 1 Tests (Skeletal)
- Bridge creation with correct initialization state
- Timeout configuration
- Status queries (is_initialized, is_connected, has_error)
- close() operation

### Phase 5 Tests (Full)
- HTTP: Send/receive valid messages, parse JSON, error on invalid JSON
- IPC: Frame encoding/decoding, length prefix validation, pipe timeouts
- Message: to_json/to_binary round-trip, attribute serialization
- Stress: High-frequency sends (1000+ msg/sec for HTTP, 10000+ for IPC)
- Error injection: Connection failures, timeout recovery, malformed frames

### Phase 6 Tests (Adversarial)
- IPC: Frame size boundary tests (0 bytes, 4 bytes, 4GB)
- HTTP: Large payloads (100MB), slow client reads, abrupt disconnections
- Messages: Circular JSON references, null attributes, missing required fields
- Concurrency: SCOOP tests with multiple concurrent bridges

## Design Decisions

### 1. Unified Bridge Interface
**Decision:** All transports implement PYTHON_BRIDGE (HTTP, IPC, gRPC)

**Rationale:**
- Allows Python to switch transports without code changes
- Each transport optimized for its scenario (HTTP for cross-machine, IPC for same-machine ultra-low-latency)
- Pluggable architecture enables future transports

### 2. Message Framing for IPC
**Decision:** 4-byte big-endian length prefix + binary payload

**Rationale:**
- Simple, proven pattern (used in many RPC systems)
- Allows streaming without full message buffering
- Handles arbitrary message sizes (up to 4GB theoretical)
- Avoids delimiter-based framing (no need to escape/unescape)

### 3. JSON Serialization for All Transports
**Decision:** HTTP sends JSON, IPC sends JSON (in binary form)

**Rationale:**
- Single serialization path (to_json)
- Flexible attribute storage (HASH_TABLE)
- Human-readable for debugging
- Compatible with Python json module

### 4. Separate Bridge Instances for Each Connection
**Decision:** Each bridge instance handles one client (no pooling in Phase 1)

**Rationale:**
- Simplifies state management
- Clearer error semantics (which connection failed?)
- Phase 2 can add connection pooling if needed

### 5. Synchronous Message I/O
**Decision:** send_message and receive_message are synchronous (blocking)

**Rationale:**
- Simpler contracts and state management
- SCOOP handles concurrency at library level
- Phase 2 can add async variants if needed

## Dependency Risks and Mitigations

### Risk 1: simple_http unavailable or breaks API
**Mitigation:**
- Phase 1 use: simple_http assumed stable (v1.0+)
- If breaking change: version constraint in ECF, manual API adapter
- Phase 2: Consider simple_http_ng (next-gen) if original deprecated

### Risk 2: JSON serialization complexity
**Mitigation:**
- Use simple_json library (already integrated)
- to_json/to_binary are deferred (implementations isolated to Phase 4)
- Phase 5 adds comprehensive JSON round-trip tests

### Risk 3: Windows-specific IPC implementation
**Mitigation:**
- Phase 1: Windows only (named pipes)
- Phase 2: Add POSIX support (Unix domain sockets)
- Abstraction via BRIDGE interface already in place

## Performance Targets and Verification

### HTTP Bridge
- **Target:** ≤100ms (p95) for 10KB payload, ≥1000 req/sec
- **Verification:** Phase 6 load tests with 1000 concurrent requests

### IPC Bridge
- **Target:** ≤10ms (p95) for 1KB payload, ≥10,000 msg/sec
- **Verification:** Phase 6 stress tests with sustained 10,000 msg/sec

### gRPC Bridge (Phase 2)
- **Target:** ≤5ms (p95) for typical 1KB, ≥50,000 msg/sec
- **Verification:** Phase 6 benchmarks

## Rollback Strategy

If implementation reveals unfeasible contracts:
- HTTP: Relax timeout, increase buffer sizes, accept lower throughput
- IPC: Switch to TCP/IP localhost if named pipes problematic
- Messages: Add optional fields, support schema versioning
- Return to Phase 2 (re-review with oracle) if major changes needed
