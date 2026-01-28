# Changelog

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
