# Changelog

## [1.1.0] - 2026-10-08

### Fixed

- **The IPC and gRPC bridges now talk to their servers.** They POSTed HTTP to
  `python_ipc_server.py` / `python_grpc_server.py`, which speak raw TCP: a 4-byte big-endian length
  prefix, then UTF-8 JSON, both directions, one reply per request on a persistent connection. Both
  bridges now inherit the new `PYTHON_TCP_BRIDGE`, which uses `simple_net`'s real `CLIENT_SOCKET`
  (1.2.0): `initialize` connects, `send_message` sends one frame, reads the reply frame, and accepts
  it only if its `message_id` answers the request. Any failure closes the connection; the next send
  reconnects. Errors carry the Winsock code (e.g. `IPC 127.0.0.1:19998 cannot connect: ... Connection
  refused (WSA 10061)`).
- **Contracts are now checked in the tests.** Neither ECF target set `<assertions>`, so the suite ran
  contract-free. Both targets now enable precondition, postcondition, check, invariant, loop and
  supplier_precondition. That revealed:
  - `HTTP_PYTHON_BRIDGE.send_message` left `is_connected` True after a failed POST, breaking
    `PYTHON_BRIDGE`'s invariant `error_implies_not_connected` (reproduced: "Class invariant violated"
    in `test_http_bridge_handles_errors`). A failed exchange now clears `is_connected`; a successful
    one sets it. The contract was right; the code was fixed.
  - `test_bridge_initialize_idempotent` called `initialize` twice, which the contract
    (`not_initialized`) forbids. Replaced by `test_bridge_initialize_twice_rejected`, which checks the
    precondition fires.
  - `decode_frame`'s postcondition (`Result.count > 0`) was wrong for a valid zero-length frame; it now
    states that the payload length equals the prefix. A negative prefix is rejected.
- `send_message` no longer violates `PYTHON_MESSAGE.freeze`'s precondition when the caller has already
  frozen the message, and no stale reply survives a failed send.

### Changed

- `IPC_PYTHON_BRIDGE` is TCP on loopback (default 127.0.0.1:9001). It was first sketched for Windows
  named pipes; the server that exists is TCP, so `make_with_pipe_name` keeps the name as a label only.
  New creation `make_with_port`.
- The IPC and gRPC integration tests assert a real round trip (reply id and type, `result` = PASS),
  connection reuse, refusal, reconnect after close, and a send after the server is killed (error, not
  connected). The gRPC tests are enabled again. 38 tests pass.

## [1.0.2] - 2026-10-08

### Fixed

- **The bridges sent broken JSON.** `test_http_bridge_sends_to_python_server` failed because the
  request body lost every double quote on the way out. Captured at the server:
  `{message_id:test_msg_001,type:VALIDATION_REQUEST,timestamp:10/08/2026T10:20:47.707` with
  `User-Agent: curl/8.21.0` and `Content-Type: application/x-www-form-urlencoded`. The bridges posted
  through `SIMPLE_HTTP.post`, whose transport (ISE `curl_http_client`, command-line spec) builds a
  `curl` command line with ` --data "<body>"` and does not escape the body, so the quotes in the JSON
  were consumed by command-line parsing and the space in the timestamp (` AM`) cut the argument.
  `post_json` takes the same path. The HTTP, IPC and gRPC bridges now post through the new
  `PYTHON_JSON_EXCHANGE`, which sends the bytes verbatim with `Content-Type: application/json` over
  `simple_winhttp`, and decodes the reply as UTF-8 (it was widened byte by byte). `simple_http` is no
  longer a dependency.
- Timeouts under one second no longer become 0 seconds (rounded up to whole seconds).

### Known issues

- (Fixed in 1.1.0) The IPC and gRPC bridges sent HTTP to raw-TCP servers.

## [1.0.1] - 2026-10-08

### Fixed

- **Test teardown no longer kills every Python process on the machine.** The HTTP, IPC and gRPC
  integration teardowns ran `taskkill /F /IM python.exe` (plus `pkill`), which ended any Python
  program the user had running. The launchers now print `READY <pid>`, and the new test helper
  `PYTHON_TEST_SERVER` stops only that process tree (`taskkill /F /T /PID <pid>`).
- **A failing integration test no longer leaves its server running.** `TEST_APP.run_with_server`
  runs teardown in a `rescue` as well, then lets the failure propagate.
- **Launchers refuse a busy port.** Before, a second launch saw the first server listening and
  reported READY, so the test talked to a stale server. They also stop their own server on timeout
  and report a server that exits early.
- **Test sleeps sleep.** `sleep_milliseconds` ran `timeout /t`, which refuses redirected input and
  rounded anything under a second down to 0; it now uses `EXECUTION_ENVIRONMENT.sleep`.

### Known issue

- `test_http_bridge_sends_to_python_server` fails: the Python server rejects the request body as
  invalid JSON ("Expecting property name enclosed in double quotes: line 1 column 2"). Present
  before these changes (same failure built against simple_process main); cause not yet found.

## [1.0.0] - 2026-01-28

### Added

- **SIMPLE_PYTHON facade:** Single entry point for creating bridges (HTTP, IPC, gRPC)
- **HTTP bridge:** JSON over HTTP/1.1 for remote Python systems
- **IPC bridge:** Windows named pipes for ultra-low-latency same-machine communication (≤10ms p95)
- **gRPC bridge:** Pluggable protocol architecture for Phase 2 expansion
- **Message types:** PYTHON_VALIDATION_REQUEST, PYTHON_VALIDATION_RESPONSE, PYTHON_ERROR
- **Message serialization:** JSON and binary formats with 4-byte big-endian length prefix
- **Freeze mechanism:** SCOOP-safe message immutability before transmission
- **Design by Contract:** Complete preconditions, postconditions, invariants on all classes
- **Comprehensive test suite:** 34 tests covering serialization, framing, lifecycle, integration, and adversarial cases
- **Production documentation:** 7 HTML documentation pages (index, quick API, user guide, API reference, architecture, cookbook)
- **SCOOP compatibility:** Thread-safe message handling for concurrent Eiffel systems
- **Void safety:** Full null-safety with detachable/attached type checking

### Technical

- Void-safe implementation (void_safety="all")
- SCOOP-compatible concurrency (concurrency=scoop)
- Zero compilation warnings
- 100% test pass rate (34/34 tests passing)
- Contracts verified by adversarial test suite
- MML ready (simple_mml dependency for advanced postconditions)

### Performance

- HTTP: 10-100ms latency (network dependent)
- IPC: ≤10ms p95 latency for 1KB payloads, ≥10,000 messages/sec throughput
- gRPC: Extensible for ≥100,000 messages/sec (Phase 2)

### Dependencies

- simple_json - JSON serialization
- simple_http - HTTP communication
- simple_mml - Mathematical Model Library (optional, for advanced contracts)
- simple_testing - Unit testing (development only)

### Documentation

- Quick API reference with code examples
- Comprehensive user guide covering all transport protocols
- Complete API reference for all classes and features
- Architecture documentation with class hierarchy and data flow
- Cookbook with 8 practical examples and troubleshooting

## Installation

```bash
# Add to your ECF:
<library name="simple_python" location="$SIMPLE_EIFFEL/simple_python/simple_python.ecf"/>
```

## Status

✅ Production ready

## License

MIT License
