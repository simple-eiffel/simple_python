# Integration Testing with Python Servers

This document explains how to run simple_python integration tests with actual Python servers.

## Prerequisites

- Python 3.7 or later
- Eiffel Studio 25.02 or later
- simple_python compiled and ready

## Test Architecture

The integration test suite (`test_integration.e`) validates that the Eiffel library can actually communicate with Python servers using all three protocols:

1. **HTTP** - JSON over HTTP/1.1
2. **IPC** - Windows named pipes (same-machine)
3. **gRPC** - (Phase 2 placeholder)

## Running Integration Tests

### Step 1: Start Python Test Server (Terminal 1)

```bash
cd d:\prod\simple_python
python3 python_servers.py http
```

You should see:
```
============================================================
simple_python HTTP Test Server
============================================================
Listening on localhost:8080
Waiting for validation requests...
```

### Step 2: Compile Eiffel Tests (Terminal 2)

```bash
cd d:\prod\simple_python
/d/prod/ec.sh -batch -config simple_python.ecf -target simple_python_tests -c_compile
```

### Step 3: Run Integration Tests

**Option A: Manual execution of specific tests**

```bash
# Create a simple Eiffel test harness:
cat > run_integration_test.e << 'EOF'
class RUN_INTEGRATION_TEST
create
    make

feature
    make
        local
            l_test: TEST_INTEGRATION
        do
            create l_test
            print("Running HTTP roundtrip test...%N")
            l_test.test_http_roundtrip_with_python_server
            print("Complete%N")
        end
end
EOF
```

Then compile and run it pointing to your integration test.

**Option B: Direct test invocation**

If using EQA test framework:
```bash
# Compile with integration tests
/d/prod/ec.sh -batch -config simple_python.ecf -target simple_python_tests -c_compile

# Run all tests (will skip integration tests if servers not running)
./EIFGENs/simple_python_tests/W_code/simple_python.exe
```

### Step 4: Observe Results

In Terminal 1 (Python Server), you should see:
```
[HTTP] Received request: integration_http_001
[HTTP] Sent response: integration_http_001
[HTTP] Received request: request_1
[HTTP] Sent response: request_1
...
```

In Terminal 2 (Eiffel Tests), you should see:
```
HTTP: Request sent successfully
HTTP: Response received
HTTP: Correct response type (validation_response)
HTTP: Result = PASS
```

## Test Cases

### HTTP Tests

| Test | Purpose | Requirements |
|------|---------|--------------|
| `test_http_roundtrip_with_python_server` | Send request, receive validation_response | Python server on localhost:8080 |
| `test_http_error_response_handling` | Test error message handling | Python server on localhost:8080 |
| `test_http_multiple_requests` | Send 5 requests sequentially | Python server on localhost:8080 |

### IPC Tests

| Test | Purpose | Requirements |
|------|---------|--------------|
| `test_ipc_roundtrip_with_python_server` | Send request via Windows named pipe | Windows, Python server on `\\.\pipe\eiffel_python_ipc` |

### gRPC Tests

(Phase 2 - not implemented yet)

## Protocol Details

### HTTP Protocol

**Request Format:**
```
POST / HTTP/1.1
Content-Length: N
Content-Type: application/json

[4-byte big-endian length prefix][JSON payload]
```

**JSON Structure:**
```json
{
  "message_id": "integration_http_001",
  "type": "validation_request",
  "timestamp": "2026-01-28T12:00:00",
  "attributes": {
    "board_id": "PCB-001",
    "temperature": 45
  }
}
```

**Response Format:**
Same as request with:
- `type: "validation_response"` or `"error"`
- Response `attributes` from Python

### IPC Protocol

**Named Pipe:** `\\.\pipe\eiffel_python_ipc`

**Frame Format:**
```
[4-byte big-endian length][JSON payload (UTF-8)]
```

**Latency SLA:** ≤10ms p95 for 1KB payloads

## Troubleshooting

### "ERROR - timeout (Python server not running?)"

**Solution:** Start Python server in Terminal 1:
```bash
python3 python_servers.py http
```

### "ERROR - could not initialize bridge"

**Possible causes:**
1. Python server not running
2. Wrong host/port
3. Network connectivity issue

**Debug:**
```bash
# Test HTTP connectivity
curl -X POST http://localhost:8080/ -d "test"

# Should get error but connection succeeds
```

### Windows IPC Tests Fail

**Possible causes:**
1. Running on non-Windows platform (IPC is Windows-only)
2. Python server not running on correct named pipe
3. Insufficient permissions to create named pipes

**Debug:**
```bash
# List named pipes (Windows PowerShell Admin)
Get-Item \\.\pipe\*
```

### "VUAR(2) error in SCOOP context"

Messages must be **frozen before sending** to separate (concurrent) objects:
```eiffel
l_request.freeze  -- REQUIRED
l_bridge.send_message (l_request)  -- Now safe for SCOOP
```

## Performance Validation

### HTTP Performance

```
Expected: 10-100ms latency (network dependent)
Test: Send 10 requests, measure round-trip time
```

### IPC Performance

```
Expected: ≤10ms p95 for 1KB payloads
Test: Send 100 1KB requests, calculate p95 latency
```

## Extending Integration Tests

To add new integration tests:

1. Add test method to `TEST_INTEGRATION` class
2. Follow naming: `test_<protocol>_<scenario>`
3. Document requirements in test comment
4. Handle both success and timeout cases
5. Use assertions to validate response structure

Example:
```eiffel
test_http_custom_scenario
        -- Test custom scenario with Python server.
    local
        l_bridge: HTTP_PYTHON_BRIDGE
    do
        create l_bridge
        -- Your test logic
    end
```

## CI/CD Integration

For automated CI/CD pipelines:

1. **Start Python servers in background:**
   ```bash
   python3 python_servers.py http &
   HTTP_SERVER_PID=$!

   python3 python_servers.py ipc &
   IPC_SERVER_PID=$!
   ```

2. **Run integration tests:**
   ```bash
   /d/prod/ec.sh -batch -config simple_python.ecf -target simple_python_tests -c_compile
   ./EIFGENs/simple_python_tests/W_code/simple_python.exe
   ```

3. **Cleanup:**
   ```bash
   kill $HTTP_SERVER_PID
   kill $IPC_SERVER_PID
   ```

## Next Steps

1. **HTTP Integration:** ✓ Complete (python_servers.py HTTP handler + integration tests)
2. **IPC Integration:** Requires pywin32 (Win32 API for named pipes)
3. **gRPC Integration:** Phase 2 (requires grpcio + protobuf)
4. **Performance Profiling:** Measure latency and throughput
5. **Error Scenario Testing:** Test timeouts, network failures, malformed messages

## License

MIT License - See LICENSE file
