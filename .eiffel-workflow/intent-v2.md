# Intent: simple_python - Eiffel-Python Bridge Library (REFINED v2)

**Date:** January 28, 2026
**Status:** Phase 0 - Intent Refined After AI Review
**AI Review Applied:** Yes (Qwen2.5-Coder 14B)

---

## What

A production-grade, Design-by-Contract-verified bridge library that enables seamless communication between Eiffel (high-assurance validation, embedded code verification) and Python (orchestration, analysis, visualization, hardware control).

**Three bridge protocols supported:**
- **HTTP REST Bridge** - Python clients call Eiffel validators via JSON over HTTP
- **IPC Named Pipes Bridge** - Same-machine, ultra-low-latency communication (Windows)
- **gRPC RPC Bridge** - Protocol Buffer RPC for distributed validation (Phase 2)

**Library provides:**
- SIMPLE_PYTHON facade (entry point)
- PYTHON_BRIDGE deferred interface (contract-based semantics)
- PYTHON_MESSAGE, PYTHON_VALIDATION_REQUEST, PYTHON_VALIDATION_RESPONSE classes
- Full Design by Contract on 100% of public interfaces
- HTTP_PYTHON_BRIDGE, IPC_PYTHON_BRIDGE, GRPC_PYTHON_BRIDGE implementations
- Python client library (PyPI package with simple `from simple_python import validate` API)

---

## Why

**Business Need:** Industrial manufacturers validate control boards and embedded systems using Eiffel's type-safe, contract-verified code but orchestrate testing and analysis in Python.

**Current State:** No unified bridge exists. Manufacturers resort to:
- Custom FFI bindings (error-prone, maintenance burden)
- Ad-hoc integration scripts (unmaintainable, no contracts)
- Separate tools with manual coordination (inefficient)

**Opportunity:** Deliver a library that:
1. Leverages Eiffel's unique advantages (Design by Contract, SCOOP concurrency, void safety, type system)
2. Integrates seamlessly with Python's rich ecosystem (NumPy, SciPy, visualization tools)
3. Provides production-grade reliability with quantified SLAs
4. Enables low-latency validation (IPC for same-machine, HTTP for distributed)

---

## Users

| User Type | Need | How They Use It |
|-----------|------|-----------------|
| **Embedded System Validator** | Verify control board firmware with contract-certified Eiffel code | Run Eiffel validators in production, call from Python orchestration |
| **Test Automation Engineer** | Orchestrate complex validation workflows across multiple systems | Call Eiffel validators from Python test harness, aggregate results |
| **Hardware Engineer** | Validate PCB/FPGA designs against Eiffel specifications | Use Python to drive validation, collect telemetry, analyze failures |
| **Data Analyst** | Analyze validation results, generate reports, visualize trends | Call validators via HTTP, process JSON results with Pandas/NumPy |
| **DevOps Engineer** | Deploy validation infrastructure as containerized service | Run Eiffel validator as HTTP server, manage via Docker/Kubernetes |

---

## Acceptance Criteria

### Phase 1 (MVP - HTTP + IPC)

**Functional Requirements:**
- [ ] HTTP REST bridge: Python clients POST validation requests, receive JSON responses
- [ ] IPC named pipes bridge: Same-machine low-latency communication via message framing
- [ ] PYTHON_BRIDGE deferred interface with full Design by Contract contracts
- [ ] PYTHON_MESSAGE, REQUEST, RESPONSE, ERROR classes with invariants
- [ ] Integration tests for both HTTP and IPC bridges
- [ ] README with quick-start, architecture overview, API reference
- [ ] Usage examples (HTTP Python client, IPC Python client)

**Quality Requirements:**
- [ ] **Code Coverage:** ≥90% line coverage, ≥85% branch coverage
- [ ] **Test Suite:** ≥100 unit tests, ≥20 integration tests, ≥5 stress tests
- [ ] **Performance:** HTTP response ≤100ms (p95), IPC response ≤10ms (p95)
- [ ] **Reliability:** <0.1% error rate under sustained load (1000 req/sec)
- [ ] **Zero compilation warnings** (strict policy)
- [ ] **Python client library** published to PyPI (simple_python_client==1.0.0)

**Documentation:**
- [ ] README with quick-start, features, prerequisites
- [ ] Architecture guide (class hierarchy, data flow, design rationale)
- [ ] API documentation (contracts, usage patterns)
- [ ] Usage examples (HTTP Python client, IPC Python client)
- [ ] Troubleshooting guide (common issues, solutions)

### Phase 2 (Future - gRPC + Linux) - **Q3 2026** (Estimated)

**Prerequisites for Phase 2:**
- Phase 1 production release and 2-month stabilization period
- simple_grpc library development complete (dependency)

**Phase 2 Features:**
- [ ] gRPC RPC bridge for distributed validation (requires simple_grpc)
- [ ] Linux IPC support (AF_UNIX sockets, requires simple_ipc_unix)
- [ ] Automatic retry with exponential backoff (HTTP)
- [ ] SCOOP concurrent validation support
- [ ] simple_logger integration (structured logging)
- [ ] Docker container (production-ready deployment)

---

## Out of Scope

| Item | Why | When |
|------|-----|------|
| Linux IPC | Windows primary; Linux is Phase 2 work | Phase 2 (Q3 2026) |
| CAN bus integration | Separate library (simple_can) | Future phase |
| TLS/mTLS encryption | Use platform HTTPS; mTLS in future | Phase 2+ |
| Cloud deployment | Standalone focus; cloud ops are customer responsibility | N/A |
| Advanced serialization | JSON + binary framing sufficient for MVP | Phase 2 |
| Custom validation rules | Customers bring their own Eiffel validators | N/A |
| GUI/Web UI | Python ecosystem responsibility; Eiffel provides API only | N/A |

---

## Technical Specifications

### Platform Support

**Eiffel:**
- EiffelStudio 25.02+ (void_safety="all", concurrency=scoop)

**Python:**
- **Minimum:** Python 3.8
- **Tested on:** 3.8, 3.9, 3.10, 3.11, 3.12
- **PyPI Package:** `simple-python-client>=1.0.0`

**Operating Systems:**
- Phase 1: Windows 10/11 (IPC named pipes)
- Phase 1: Windows, Linux, macOS (HTTP via simple_http)
- Phase 2: Linux support (AF_UNIX sockets)

**HTTP Support:**
- **Mandatory:** HTTP/1.1 (RFC 7231)
- **Optional:** HTTP/2 (RFC 7540)
- **HTTPS:** Port 443 (standard)

### Performance SLAs

| Metric | Target | Measurement |
|--------|--------|-------------|
| HTTP Response Time | ≤100ms (p95) | POST /validate with 10KB payload |
| IPC Response Time | ≤10ms (p95) | MESSAGE_FRAMING with 1KB payload |
| Throughput | ≥1000 req/sec | Sustained load test (60s) |
| Error Rate | <0.1% | Under load (1000 req/sec) |
| Uptime SLA | ≥99.5% | Monthly average |

### Reliability & Quality

| Metric | Target | Measurement |
|--------|--------|-------------|
| Code Coverage | ≥90% | Line coverage (tool: EiffelStudio metrics) |
| Branch Coverage | ≥85% | Branch coverage (critical paths) |
| Defect Density | <5 defects/KLOC | After Phase 1 release |
| Test Pass Rate | 100% | All phases |
| Compilation Warnings | 0 | Strict policy |

---

## Dependencies (REQUIRED - simple_* First Policy)

### Phase 1 Required Dependencies

| Need | Library | Version | Justification |
|------|---------|---------|---------------|
| HTTP Server/Client | simple_http | 1.0+ | Contract-verified, void-safe |
| JSON Serialization | simple_json | 1.0+ | Void-safe, MML-friendly |
| IPC Communication | simple_ipc | 1.0+ | Windows named pipes abstraction |
| Message Protocol | (custom) | 1.0 | Binary framing: 4-byte length prefix + payload |
| Logging | simple_logger | 1.0+ | Structured diagnostics, JSON output |
| Testing | simple_testing | 1.0+ | EQA_TEST_SET for contract-based tests |
| Mathematical Models | simple_mml | 1.0+ | MML_MAP, MML_SET for frame conditions |

### ISE Allowed (No simple_* Alternative Exists)

| Library | Version | Purpose |
|---------|---------|---------|
| base | latest | STRING, INTEGER, ARRAY, HASH_TABLE |
| time | latest | DATE, TIME, DATE_TIME for logging |
| testing | latest | EQA_TEST_SET for unit tests |

### Phase 2 Dependencies (TBD)

| Need | Library | Status | ETA |
|------|---------|--------|-----|
| gRPC bindings | simple_grpc | Proposed | Q2 2026 |
| Linux IPC | simple_ipc_unix | Proposed | Q2 2026 |

### Dependency Risk Mitigation

**Strategy:**
1. **Version Pinning** - Lock all dependencies in ECF (no floating versions)
2. **Monthly Reviews** - Dependency update cycle (testing required after each update)
3. **Fallback Mechanisms** - IPC as alternative if simple_http fails; HTTP as fallback for IPC errors
4. **Integration Testing** - Comprehensive tests after any dependency upgrade
5. **Vendor Monitoring** - Track simple_* library releases, security advisories, breaking changes

### Gaps Identified (Future simple_* Libraries)

| Gap | Current Workaround | Proposed simple_* | ETA |
|-----|-------------------|-------------------|-----|
| gRPC bindings | Custom protobuf + hand-coded marshaling | simple_grpc | Q2 2026 |
| Linux IPC | Windows only (Phase 1) | simple_ipc_unix | Q2 2026 |

---

## Architecture & Design

### Class Hierarchy (Unified Bridge Pattern)

```
SIMPLE_PYTHON (Facade)
├── new_http_bridge(host, port) → HTTP_PYTHON_BRIDGE
├── new_ipc_bridge(pipe_name) → IPC_PYTHON_BRIDGE
└── new_grpc_bridge(host, port) → GRPC_PYTHON_BRIDGE [Phase 2]

PYTHON_BRIDGE (Deferred - Unified Interface)
├── initialize: BOOLEAN
├── send_message(msg: PYTHON_MESSAGE): BOOLEAN
├── receive_message: detachable PYTHON_MESSAGE
├── close
└── is_connected: BOOLEAN

HTTP_PYTHON_BRIDGE (PYTHON_BRIDGE)
├── HTTP Server via simple_http
├── JSON Serialization via simple_json
├── REST endpoints: POST /validate, GET /status
└── Error handling: HTTP status codes (200, 400, 500)

IPC_PYTHON_BRIDGE (PYTHON_BRIDGE)
├── Named Pipes via simple_ipc
├── Message Framing (4-byte length prefix)
├── Bidirectional streaming
└── Windows-only (Phase 1)

GRPC_PYTHON_BRIDGE (PYTHON_BRIDGE) [Phase 2]
├── gRPC Server via simple_grpc
├── Protocol Buffers serialization
└── Distributed validation support

PYTHON_MESSAGE (Deferred - Shared Protocol)
├── PYTHON_VALIDATION_REQUEST
├── PYTHON_VALIDATION_RESPONSE
├── PYTHON_ERROR
└── PYTHON_SERIALIZER (JSON, Binary, Protocol Buffers)
```

### Design Patterns Applied

1. **Facade Pattern** - SIMPLE_PYTHON provides single entry point
2. **Bridge Pattern** - PYTHON_BRIDGE deferred with multiple implementations (HTTP, IPC, gRPC)
3. **Adapter Pattern** - Unified bridge interface with pluggable transport layers
4. **Factory Pattern** - Bridge creation with new_http_bridge, new_ipc_bridge, new_grpc_bridge
5. **Template Method** - Shared message protocol in PYTHON_MESSAGE
6. **Builder Pattern** - Fluent API for configuring bridges before initialization

### Design by Contract Enforcement

**Contract Levels:**
1. **Preconditions** - Input validation (non-empty host, valid port range)
2. **Postconditions** - State changes (bridge initialized, message sent)
3. **Invariants** - Class state consistency (is_connected implies socket valid)
4. **Frame Conditions** - Collection immutability (MML |=| for HASH_TABLE, ARRAYED_LIST)

**Contract Verification Process:**
- Compile with `assertions (precondition=true, postcondition=true, invariant=true)`
- Unit tests derive from postconditions (contract-based testing)
- Integration tests verify invariant maintenance across state transitions
- Stress tests validate contracts under load (1000 req/sec, 10MB payloads)

---

## Technology Decisions (Refined)

| Decision | Choice | Rationale | Risk Mitigation |
|----------|--------|-----------|-----------------|
| HTTP Framework | simple_http | Contract-verified, void-safe | Fallback to IPC if HTTP fails |
| JSON Serialization | simple_json | Void-safe, MML postconditions | Version pinning, monthly updates |
| IPC (Windows) | Named pipes | Low-latency, OS-native, standard | Dedicated integration tests |
| Message Protocol | 4-byte length + payload | Simple, robust, binary-safe | Wire format documentation |
| Python Integration | PyPI package | Standard distribution, version control | Semantic versioning (semver) |
| Concurrency Model | SCOOP-compatible (Phase 2) | Eiffel separate semantics | Producer-consumer test patterns |
| Testing Framework | simple_testing (EQA_TEST_SET) | Contract-based test derivation | Adversarial/stress test suite |
| Logging | simple_logger | Structured diagnostics, JSON output | Detailed troubleshooting guide |

---

## Testing Strategy

### Phase 1 Test Coverage

**Unit Tests (≥100 tests):**
- PYTHON_MESSAGE contracts (preconditions, postconditions, invariants)
- HTTP_PYTHON_BRIDGE initialization, connection, send, receive, close
- IPC_PYTHON_BRIDGE message framing, error handling
- PYTHON_SERIALIZER JSON encoding/decoding
- Error handling (malformed input, timeouts, connection drops)

**Integration Tests (≥20 tests):**
- HTTP client-server roundtrip (request → validate → response)
- IPC client-server roundtrip (message → validate → reply)
- Error scenarios (connection refused, timeout, invalid JSON)
- Concurrent requests (5, 10, 50 simultaneous)

**Stress Tests (≥5 tests):**
- Sustained load: 1000 req/sec for 60 seconds (HTTP)
- Large payloads: 10MB validation request/response
- Connection cycling: 1000 connect/disconnect cycles
- Memory stability: Monitor for leaks over 24-hour test

**Performance Tests:**
- Baseline latency: HTTP ≤100ms (p95), IPC ≤10ms (p95)
- Throughput: ≥1000 req/sec sustained
- Error rate: <0.1% under load

---

## MML Decision (Contract Model Queries)

**Decision: YES - Required**

**Collections Requiring Frame Conditions:**
- PYTHON_MESSAGE: `attributes: HASH_TABLE [STRING, SIMPLE_JSON_VALUE]` → `attributes_model: MML_MAP`
- HTTP_PYTHON_BRIDGE: `active_connections: ARRAYED_LIST [STRING]` → `connections_model: MML_SET`
- Validation results: `responses: ARRAYED_LIST [PYTHON_VALIDATION_RESPONSE]` → `results_model: MML_SEQUENCE`

**Contract Example:**
```eiffel
set_attribute (a_key: STRING; a_value: SIMPLE_JSON_VALUE)
  require
    key_not_empty: not a_key.is_empty
  do
    attributes.put (a_value, a_key)
  ensure
    -- Direct effect
    attribute_set: attributes.has (a_key) and then attributes [a_key] = a_value

    -- Frame condition: other attributes unchanged
    others_unchanged: old attributes.removed (a_key) |=| attributes.removed (a_key)
```

---

## Timeline & Milestones

### Phase 1: MVP (0-4 months from approval)

| Milestone | Date | Deliverable |
|-----------|------|-------------|
| Phase 1: Contracts | Week 1-2 | Class skeletons with contracts |
| Phase 2: Review | Week 3-4 | AI review + refinement |
| Phase 3: Tasks | Week 5 | Implementation task breakdown |
| Phase 4: Implementation | Week 6-12 | Feature bodies, 100+ tests |
| Phase 5: Verification | Week 13-16 | Test completion, 90% coverage |
| Phase 6: Hardening | Week 17-18 | Adversarial/stress tests |
| Phase 7: Release | Week 19-20 | v1.0.0 production release |

### Phase 2: Enhanced (Q3 2026 - 4+ months from Phase 1 release)

**Prerequisites:**
- Phase 1 production release (v1.0.0)
- 2-month stabilization period (bug fixes, performance tuning)
- simple_grpc library available (if not, defer)

**Planned Features:**
- gRPC bridge (requires simple_grpc)
- Linux IPC (requires simple_ipc_unix)
- Automatic retry with exponential backoff
- SCOOP concurrent validation
- Docker container
- Performance benchmarking

---

## Success Criteria (Final Approval Gate)

**Before Phase 1 Contracts Can Start:**

- [ ] **Intent Document:** intent-v2.md approved (THIS DOCUMENT)
- [ ] **AI Review:** 10 probing questions answered and incorporated
- [ ] **Dependencies:** All simple_* libraries verified to exist or on roadmap
- [ ] **Performance SLAs:** Stakeholders agree on HTTP ≤100ms, IPC ≤10ms targets
- [ ] **Testing Metrics:** Team commits to ≥90% line, ≥85% branch coverage
- [ ] **Timeline:** 4-month Phase 1 timeline acceptable
- [ ] **Scope:** Phase 1 (HTTP + IPC) vs Phase 2 (gRPC + Linux) boundary accepted

---

## Next Steps

### Immediate (Upon Approval)

1. ✅ Create Phase 1 contracts (run `/eiffel.contracts d:\prod\simple_python`)
2. Submit contracts for adversarial AI review (Ollama, Claude, Grok, Gemini)
3. Refine based on review feedback
4. Break into implementation tasks (Phase 3)

### Phase 1 (After Contracts)

5. Implement feature bodies (Phase 4)
6. Flesh out tests (Phase 5)
7. Adversarial/stress testing (Phase 6)
8. Production release (Phase 7)

### Ongoing

- Monthly dependency review
- Quarterly performance benchmarking
- Track simple_grpc, simple_ipc_unix for Phase 2 enablement

---

## Questions Answered from AI Review

| AI Question | Answer |
|-------------|--------|
| Define "production-grade" | ≥99.5% uptime SLA, <0.1% error rate, response ≤100ms (HTTP) / ≤10ms (IPC) |
| Define "low-latency" | ≤10ms for IPC named pipes, ≤100ms for HTTP |
| Specify Python versions | 3.8+ required, tested on 3.8, 3.9, 3.10, 3.11, 3.12 |
| Specify HTTP versions | HTTP/1.1 mandatory, HTTP/2 optional, HTTPS on 443 |
| Define Phase 2 timing | Q3 2026 (estimated), after 2-month Phase 1 stabilization |
| Unify three bridges? | YES - Unified PYTHON_BRIDGE with pluggable transports (adapter pattern) |
| Sufficient MML coverage? | YES - attributes_model, connections_model, results_model with frame conditions |
| Risk mitigation for dependencies | Version pinning, monthly reviews, fallback mechanisms (IPC ↔ HTTP), integration testing |
| Define "contract-verified" | 100% of public interfaces have require/ensure/invariant; verified by unit tests derived from postconditions |
| Beyond code coverage | Added branch coverage (≥85%), stress tests, performance benchmarks, real-world scenario testing |

---

## Approval Checklist

**By signing below, you approve:**

- [ ] This intent document accurately describes the simple_python library
- [ ] Phase 1 scope (HTTP + IPC) is appropriate for MVP
- [ ] Phase 2 deferral (gRPC + Linux) is justified
- [ ] Performance SLAs (HTTP ≤100ms, IPC ≤10ms) are achievable
- [ ] Testing metrics (≥90% line, ≥85% branch coverage) are acceptable
- [ ] 4-month Phase 1 timeline is feasible
- [ ] simple_* dependency strategy (with fallbacks) is sound
- [ ] MML decision and frame conditions are sufficient

**Approval Status:** ⏳ AWAITING USER SIGN-OFF

---

**Ready to proceed to Phase 1 (Contracts)?**