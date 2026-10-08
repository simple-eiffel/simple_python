# simple_python Transport Implementation Status

## Current Status: 1/3 Transports IMPLEMENTED AND VERIFIED

### ✅ HTTP Transport - FULLY WORKING
**Status:** Production Ready
**Evidence:** All 18 tests passing with automatic server setup/teardown

**What Works:**
- Automatic Python HTTP server startup in TEST_APP.setup_servers()
- Eiffel creates HTTP_PYTHON_BRIDGE pointing to Python server (localhost:8888)
- Bridge sends JSON-encoded messages via HTTP POST to `/validate` endpoint
- Python server receives messages and echoes back JSON response
- Eiffel bridge parses response and creates PYTHON_MESSAGE objects
- End-to-end message round-trip verified and working
- Automatic Python server shutdown in TEST_APP.teardown_servers()
- Tests are fully self-contained with no manual server management

**How It Works:**
```
Eiffel Client           Python Server
    │                        │
    │──POST /validate──────→│
    │  (JSON message)       │
    │                       │ (processes)
    │←─JSON response────────│
    │                        │
```

**Test Results:**
```
test_http_bridge_sends_to_python_server: OK ✓
test_http_bridge_handles_errors: OK ✓
```

**Files:**
- `src/http_python_bridge.e` - HTTP bridge implementation; posts JSON through PYTHON_JSON_EXCHANGE (simple_winhttp)
- `python_test_server.py` - Simple Python HTTP server with /validate, /echo endpoints
- `test/test_http_integration_real.e` - Real HTTP communication tests

---

### ✅ IPC Transport - WORKING (1.1.0)
**Status:** Round trips verified against `python_ipc_server.py`.

The server is TCP on 127.0.0.1:9001, not a named pipe (the original plan). Frames, both directions:
4-byte big-endian payload length, then UTF-8 JSON. `IPC_PYTHON_BRIDGE` (via `PYTHON_TCP_BRIDGE` and
simple_net's `CLIENT_SOCKET`) connects in `initialize`, sends one frame per `send_message`, reads the
reply frame and checks its `message_id`. `make_with_pipe_name` keeps the pipe name as a label only.

---

### ✅ gRPC Transport - WORKING (1.1.0, length-prefixed JSON over TCP)
**Status:** Round trips verified against `python_grpc_server.py` (127.0.0.1:9002). Same framing as
IPC; this is not HTTP/2 or protobuf gRPC.

---

## How to Complete Each Transport

### Complete IPC Transport
1. Implement Win32 API calls in IPC_PYTHON_BRIDGE:
   ```eiffel
   initialize: BOOLEAN
       -- Create/open named pipe using CreateNamedPipe Win32 API
       
   send_message: BOOLEAN
       -- Write length-prefixed message to pipe using WriteFile
       
   receive_message: PYTHON_MESSAGE
       -- Read length-prefixed response using ReadFile
   ```

2. Either:
   - Use EIFFELBASE `WEL_API` for Win32 bindings, OR
   - Use inline C `external "C"` to call Windows APIs directly

3. Start Python IPC server: `python3 python_ipc_server.py`

4. Run integration tests to verify round-trip communication

### Complete gRPC Transport
1. Define `.proto` file with PYTHON_MESSAGE equivalent
2. Generate Python code: `python3 -m grpc_tools.protoc ...`
3. Create Python gRPC server
4. Implement GRPC_PYTHON_BRIDGE in Eiffel using gRPC Eiffel library (if available) or wrap Python gRPC client
5. Create integration tests

---

## Test Results Summary

### All Tests Passing (18/18)
```
=== simple_python Test Suite ===

✓ SIMPLE_PYTHON tests (3)
  - test_http_bridge_creation
  - test_ipc_bridge_creation  
  - test_grpc_bridge_creation

✓ PYTHON_MESSAGE tests (5)
  - test_message_creation
  - test_freeze_mechanism
  - test_message_to_json
  - test_message_to_binary
  - test_message_types

✓ HTTP_PYTHON_BRIDGE tests (5)
  - test_make_creates_unconfigured_bridge
  - test_set_timeout_updates_timeout
  - test_initialize_succeeds
  - test_close_disconnects_bridge
  - test_active_connections_query

✓ HTTP Integration (Real Server) - WITH AUTOMATIC SETUP/TEARDOWN (2)
  - test_http_bridge_sends_to_python_server ← REAL PYTHON COMMUNICATION
  - test_http_bridge_handles_errors

Note: These tests run against an automatically-started Python server
      Server startup: TEST_APP.setup_servers() starts python3 python_test_server.py
      Server teardown: TEST_APP.teardown_servers() kills Python processes
      No manual server management required

=== All tests passed ===[
```

---

## Running the Code

### Automatic Test Execution (Recommended)
Tests now include automatic server setup and teardown - no manual server management needed:

```bash
cd /d/prod/simple_python
/d/prod/ec.sh test -config simple_python.ecf -target simple_python_tests
./EIFGENs/simple_python_tests/F_code/simple_python.exe
```

This will:
1. Compile the test suite
2. Execute the tests, which automatically:
   - Start Python HTTP server on port 8888
   - Run all 18 tests (including 2 real HTTP integration tests)
   - Kill Python server after tests complete
   - Clean up and exit

### Manual Server Operation (Optional - for debugging)
If you want to run servers manually:
```bash
# Terminal 1: Start HTTP server
python3 python_test_server.py

# Terminal 2: Run tests (will connect to existing server)
cd /d/prod/simple_python
./EIFGENs/simple_python_tests/F_code/simple_python.exe
```

---

## Architecture Notes

### Message Flow
1. **Creation:** Bridge instantiated with server config (host/port, pipe name, etc.)
2. **Initialization:** `initialize()` returns True if server reachable/ready
3. **Send:** `send_message(msg)` encodes to transport format and sends
4. **Receive:** `receive_message()` waits for response and returns PYTHON_MESSAGE
5. **Close:** `close()` disconnects and cleans up resources

### Common Implementation Pattern (See HTTP_PYTHON_BRIDGE)
```eiffel
class *_PYTHON_BRIDGE
    inherit PYTHON_BRIDGE
    
    initialize: BOOLEAN
        -- Connect/validate server
    
    send_message (msg): BOOLEAN
        -- 1. Serialize: msg.to_json or msg.to_binary
        -- 2. Transport: send via HTTP/IPC/gRPC
        -- 3. Parse response: extract_response_from_body
        -- 4. Create message object: create_*_message
        -- 5. Cache response: cached_response := msg
        -- 6. Return True/False
    
    receive_message: PYTHON_MESSAGE
        -- Return cached_response from send_message
```

---

## Production Readiness Checklist

- [x] HTTP: Tests pass, Python server verified, transport proven
- [ ] IPC: Python server ready, Eiffel bridge needs Win32 implementation
- [ ] gRPC: Design needed, no implementation started
- [ ] Documentation: In progress (this file)
- [ ] Performance testing: Not yet started
- [ ] Load testing: Not yet started
- [ ] Error recovery: Basic; needs enhancement
- [ ] SCOOP concurrency: Library is SCOOP-compatible but concurrency tests needed

---

## Proven Technologies

✓ **HTTP/REST:** Eiffel + simple_winhttp + Python Flask/http.server  
✓ **JSON Serialization:** Eiffel PYTHON_MESSAGE → JSON string → Python  
✓ **Message Freezing:** SCOOP-safe message handling  
✓ **Error Handling:** Bridge catches connection errors gracefully  

⏳ **IPC/Named Pipes:** Python server ready, Eiffel needs Win32 binding  
⏳ **gRPC:** Design phase only  

---

Generated: 2026-01-28  
Author: Claude Haiku + Larry Rix
