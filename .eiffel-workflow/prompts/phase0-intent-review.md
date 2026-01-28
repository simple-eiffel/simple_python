# Intent Review Request - simple_python

**Instructions:** Review the intent document below and generate probing questions to clarify vague language, identify missing requirements, and surface implicit assumptions.

## Review Criteria

Look for:
1. **Vague language:** Words like "production-grade", "low-latency", "seamless", "contract-verified" without concrete definitions
2. **Missing edge cases:** What happens with network failures? Malformed input? Timeouts?
3. **Untestable criteria:** Are acceptance criteria specific and measurable? ("≥90% coverage", "zero warnings")
4. **Hidden dependencies:** Are there assumptions about Python versions, Eiffel features, OS support?
5. **Scope ambiguity:** Is Phase 1 vs Phase 2 clear? Are boundaries justified?
6. **Architecture concerns:** Do class hierarchies make sense? Are design patterns appropriate?
7. **Design-by-Contract specifics:** Which contracts are critical? Which might be over-constrained?
8. **Risk exposure:** What if dependencies (simple_http, simple_json) have bugs? Mitigation?

## Output Format

Provide 8-10 probing questions. For each:
- Quote the vague phrase or unclear requirement
- Explain why it's ambiguous or risky
- Offer 2-3 concrete alternatives the user can choose from

---

## Intent Document to Review

# Intent: simple_python - Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Status:** Derived from Pre-Phase Specification (Steps 1-8 COMPLETE)

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
3. Provides production-grade reliability (contracts verify every interaction)
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

- [ ] HTTP REST bridge: Python clients POST validation requests, receive JSON responses
- [ ] IPC named pipes bridge: Same-machine low-latency communication via message framing
- [ ] PYTHON_BRIDGE deferred interface with full Design by Contract contracts
- [ ] PYTHON_MESSAGE, REQUEST, RESPONSE, ERROR classes with invariants
- [ ] 100+ passing tests (≥90% code coverage, zero warnings)
- [ ] Python client library published to PyPI with simple facade API
- [ ] Integration tests for both HTTP and IPC bridges
- [ ] README with quick-start, architecture overview, API reference
- [ ] Usage examples (HTTP Python client, IPC Python client)

### Phase 2 (Future - gRPC + Linux)

- [ ] gRPC RPC bridge for distributed validation
- [ ] Linux IPC support (AF_UNIX sockets)
- [ ] Automatic retry with exponential backoff
- [ ] SCOOP concurrent validation support
- [ ] simple_logger integration (structured logging)
- [ ] Docker container (production-ready deployment)

---

## Out of Scope

| Item | Why | When |
|------|-----|------|
| Linux IPC | Windows primary; Linux is future work | Phase 2 |
| CAN bus integration | Separate library (simple_can) | Future |
| TLS/mTLS encryption | Use platform HTTPS; mTLS future work | Phase 2 |
| Cloud deployment | Standalone focus; cloud ops are customer responsibility | Phase 2 |
| Advanced serialization | JSON + binary framing sufficient for MVP | Phase 2 |
| Custom validation rules | Customers bring their own Eiffel validators | N/A |
| GUI/Web UI | Python ecosystem responsibility; Eiffel provides API only | N/A |

---

## Dependencies (REQUIRED - simple_* First Policy)

### Required Dependencies

| Need | Library | Justification |
|------|---------|---------------|
| HTTP Server/Client | simple_http | Eiffel HTTP library, contract-verified |
| JSON Serialization | simple_json | Eiffel JSON library, void-safe, no ISE dependencies |
| IPC Communication | simple_ipc | Windows named pipes abstraction |
| Message Protocol | (custom) | Binary framing with 4-byte length prefix |
| Logging | simple_logger | Structured diagnostics, integration testing |
| Testing | simple_testing | EQA_TEST_SET for contract-based tests |

### ISE Allowed (No simple_* Alternative Exists)

| Library | Purpose |
|---------|---------|
| base | Fundamental types (STRING, INTEGER, ARRAY) |
| time | DATE, TIME, DATE_TIME for logging/telemetry |
| testing | EQA_TEST_SET for unit tests |

### Explicitly NOT Used (simple_* Preferred)

| Avoid | Use Instead | Why |
|-------|-------------|-----|
| Gobo HTTP | simple_http | simple_http is designed for Eiffel ecosystem |
| ISE network | simple_http | simple_http abstracts network details |
| ISE XML | simple_json | JSON is primary protocol, not XML |

### Gaps Identified

| Gap | Current Workaround | Proposed simple_* |
|-----|-------------------|-------------------|
| gRPC bindings | Custom protobuf compiler + hand-coded marshaling | simple_grpc (future Phase 2) |
| Linux IPC | Windows only (Phase 1) | simple_ipc_unix (future) |

---

## MML Decision

**Decision: YES - Required**

**Rationale:**

simple_python includes collections that need frame conditions:
- PYTHON_MESSAGE has optional `attributes: HASH_TABLE [STRING, SIMPLE_JSON_VALUE]`
- HTTP_PYTHON_BRIDGE tracks connections (internal state)
- Validation result aggregation involves ARRAYED_LIST [PYTHON_VALIDATION_RESPONSE]

**Impact:**
- simple_mml will be added as Phase 1 dependency
- Model queries will define: attributes_model, connections_model, results_model
- Postconditions will use frame conditions (`|=|`) to specify what changed and what didn't
- Example postcondition: `old attributes.count + 1 = attributes.count and old non_modified_attrs |=| attributes.removed (a_key)`

---

## Architecture Overview (from Specification)

### Class Hierarchy

```
SIMPLE_PYTHON
├── HTTP_PYTHON_BRIDGE (PYTHON_BRIDGE)
│   ├── HTTP Server (simple_http)
│   └── JSON Serialization (simple_json)
├── IPC_PYTHON_BRIDGE (PYTHON_BRIDGE)
│   ├── Named Pipes (simple_ipc)
│   └── Message Framing (4-byte length prefix)
└── GRPC_PYTHON_BRIDGE (PYTHON_BRIDGE) [Phase 2]
    ├── gRPC Server (simple_grpc)
    └── Protocol Buffers

PYTHON_MESSAGE (deferred)
├── PYTHON_VALIDATION_REQUEST
├── PYTHON_VALIDATION_RESPONSE
└── PYTHON_ERROR

PYTHON_SERIALIZER
├── JSON_SERIALIZER (default, simple_json)
├── BINARY_SERIALIZER (message framing)
└── PICKLE_SERIALIZER [optional, future]
```

### Design Patterns

1. **Facade Pattern** - SIMPLE_PYTHON provides single entry point
2. **Bridge Pattern** - PYTHON_BRIDGE deferred with multiple implementations
3. **Factory Pattern** - Bridge creation with new_http_bridge, new_ipc_bridge
4. **Template Method** - Shared message protocol in PYTHON_MESSAGE
5. **Builder Pattern** - Fluent API for configuring bridges before initialization

### Design by Contract

- **Contracts on 100% of public interfaces** (preconditions, postconditions, invariants)
- **Message validation contracts** - Preconditions ensure valid input before processing
- **State transition contracts** - Invariants ensure bridge state consistency
- **MML frame conditions** - Model postconditions specify collections don't contain unexpected modifications

---

## Technology Decisions (from Phase 4-5 of Specification)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| HTTP Framework | simple_http | Contract-verified, void-safe, no external dependencies |
| JSON Serialization | simple_json | Void-safe, MML-friendly postconditions |
| IPC (Windows) | Named pipes | Low-latency, OS-native, standard Windows IPC |
| Message Protocol | 4-byte length prefix + payload | Simple, robust, compatible with binary protocols |
| Python Integration | PyPI package (simple_python_client) | PyPI is de facto standard for Python libraries |
| Concurrency Model | SCOOP-compatible (Phase 2) | Eiffel separate semantics for distributed validation |
| Testing Framework | simple_testing (EQA_TEST_SET) | Contract-based test derivation |
| Logging | simple_logger | Structured diagnostics, JSON output |

---

## Questions for AI Review

Please review this intent for:

1. **Vague Language** - Are "production-grade", "low-latency", "seamless" defined concretely?
2. **Missing Edge Cases** - What happens if Python sends malformed JSON? If connection drops mid-stream?
3. **Untestable Criteria** - Is "≥90% code coverage" measurable? What about "contract-verified"?
4. **Hidden Dependencies** - Are there assumptions about Python versions, HTTP versions, Windows versions?
5. **Scope Ambiguity** - Is Phase 1 vs Phase 2 boundary clear enough? Is "custom validation rules" out-of-scope correctly justified?
6. **Architecture Concerns** - Does the three-bridge model (HTTP/IPC/gRPC) make sense? Should there be a unified bridge interface?
7. **MML Decision** - Are the identified collections sufficient? Should PYTHON_BRIDGE track more state for frame conditions?
8. **Risk Mitigation** - What if simple_http or simple_json have bugs? How do we isolate dependency risk?

---

End of Intent Document
