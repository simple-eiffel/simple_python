# PARSED REQUIREMENTS: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Specification Phase:** Step 1 - Analyze and Extract Research

---

## Problem Summary

Industrial manufacturers need a production-grade, Design-by-Contract-verified bridge between Eiffel (high-assurance validation, embedded code verification) and Python (orchestration, analysis, visualization, hardware control) for control board and embedded system validation.

**Gap:** No unified bridge exists in the simple_* ecosystem. Current manufacturers resort to custom FFI bindings (error-prone) or ad-hoc integration scripts (unmaintainable).

**Opportunity:** Deliver a library that leverages Eiffel's unique advantages (Design by Contract, SCOOP concurrency, void safety, type system) while integrating seamlessly with Python's rich ecosystem.

---

## Scope

### In Scope (MUST HAVE)

**Core Bridges:**
- HTTP REST bridge (simple_http + simple_web + simple_json)
  - Python clients call Eiffel validators via HTTP POST/GET
  - JSON serialization with schema validation
  - Standard HTTP status codes (200, 400, 500)

- IPC named pipe bridge (simple_ipc, Windows)
  - Same-machine, ultra-low-latency validation
  - Message framing: 4-byte length prefix + binary payload
  - Bidirectional streaming support

- gRPC RPC bridge (conditional on socket I/O resolution)
  - See "Socket I/O Decision" section below for implementation path

**Shared Foundation:**
- PYTHON_BRIDGE deferred interface (contracts define bridge semantics)
- PYTHON_MESSAGE base class (protocol-agnostic message semantics)
- PYTHON_VALIDATION_REQUEST/RESPONSE (core message types)
- PYTHON_ERROR (error handling and reporting)
- Design by Contract on 100% of public interfaces
- Message validation contracts (preconditions ensure valid input)

**Testing & Quality:**
- Unit tests for message contracts (validate preconditions/postconditions)
- Integration tests for HTTP and IPC bridges
- Per-protocol test fixtures (isolated setup/teardown)
- ≥100 passing tests, ≥90% code coverage
- Zero compilation warnings (ZERO POLICY)

**Documentation:**
- README.md (quick start, features, prerequisites)
- Architecture guide (class hierarchy, data flow, design rationale)
- API documentation (contracts, usage patterns)
- Usage examples (HTTP client, IPC client, Python integration)
- Troubleshooting guide (common issues, solutions)

**Python Integration:**
- Python client library (PyPI package)
- Simple facade API: `from simple_python import validate; result = validate(design_data)`
- Handles HTTP and IPC connection details transparently
- Clear error handling (distinguish client vs server errors)

### In Scope (SHOULD HAVE)

- Automatic retry with exponential backoff (HTTP)
- Concurrent validation support (SCOOP processors)
- simple_logger integration (structured logging, diagnostics)
- Docker container (ready-to-deploy, no build needed)
- Performance benchmarking (measure latency, throughput)

### Out of Scope

- **Linux IPC support** - Windows primary; Linux future work
- **CAN bus integration** - Future simple_can library
- **TLS/Encryption** - Use platform-level HTTPS; mTLS in future work
- **Cloud deployment infrastructure** - Standalone focus
- **Advanced serialization** - JSON + binary framing sufficient
- **Custom validation rules** - Customers bring their own Eiffel validators
- **GUI/Web UI** - Python responsibility; Eiffel provides API only

### gRPC Bridge Implementation (No Blocker - Design Choice Only)

**Status:** NOT blocked. ISE NET library provides production-ready `NETWORK_STREAM_SOCKET`.

**Design Decision:** Should gRPC bridge use ISE NET directly, or build a simple_socket wrapper first?

**Three Implementation Approaches:**

**Option A: Use ISE NET Library Directly (Fastest)**
- Use ISE's `NETWORK_STREAM_SOCKET` from `net.ecf` library
- Effort: 0 days (ISE NET already production-ready)
- Benefit: Immediate implementation, proven, maintained by ISE
- Trade-off: Not using simple_* ecosystem pattern
- Timeline: Start gRPC immediately (1-2 days for bridge)

**Option B: Build simple_socket Wrapper (Ecosystem-First)**
- Create new `simple_socket` library wrapping `NETWORK_STREAM_SOCKET`
- Effort: 2-3 days (socket wrapper) + 1-2 days (gRPC bridge)
- Benefit: Long-term ecosystem value, clean abstraction, simple_* pattern consistency
- Trade-off: Slower initial delivery, adds library to maintain
- Timeline: Complete socket wrapper first, then gRPC bridge

**Option C: Delegate to Python subprocess (Maximum Simplicity)**
- gRPC server runs in Python subprocess via `simple_process`
- Effort: 1-2 days (gRPC bridge only, delegates to Python)
- Benefit: Zero Eiffel socket code, use Python's mature gRPC library
- Trade-off: Performance hit, Eiffel loses low-level control
- Use case: If speed-to-market critical and gRPC performance acceptable

**DECISION REQUIRED BEFORE IMPLEMENTATION:**
Choose Option A (fast), Option B (ecosystem-first), or Option C (maximum simplicity). All are viable paths. This determines the implementation approach for gRPC bridge.

---

## Functional Requirements

| ID | Requirement | Priority | Source | Acceptance Criteria |
|----|-------------|----------|--------|---------------------|
| **FR-001** | Three independent bridge implementations (HTTP, IPC, gRPC) | MUST | research/04 D-001 | All three targets compile, zero warnings; gRPC deferred to Phase 2 |
| **FR-002** | HTTP REST bridge with JSON serialization | MUST | research/03 | Python `requests` library can POST/GET to `/api/validate` endpoint; returns JSON with validation results |
| **FR-003** | IPC named pipe bridge for Windows | MUST | research/03 | Python named pipe client (`pywin32`) exchanges binary messages with Eiffel server; message framing verified |
| **FR-004** | Shared message interface (PYTHON_MESSAGE deferred) | MUST | research/04 D-002, research/05 I-002 | HTTP/IPC inherit from PYTHON_MESSAGE; all implement `to_bytes()`, `from_bytes()`, validation contracts |
| **FR-005** | Design by Contract on all public classes | MUST | research/03 FR-005 | 100% of public classes have preconditions, postconditions, invariants with MML model queries |
| **FR-006** | Request-response message semantics | MUST | research/03 FR-007 | Validation request (design data) → validate → response (errors, warnings, metadata) |
| **FR-007** | JSON Schema validation for HTTP messages | MUST | research/03 FR-008, research/04 D-004 | simple_json validates JSON payloads against schema; invalid → HTTP 400 |
| **FR-008** | Error handling with HTTP status codes | MUST | research/03 FR-010 | 200 OK (success), 400 Bad Request (client error), 500 Internal Server Error (server error); error messages in payload |
| **FR-009** | Message validation contracts (preconditions) | MUST | research/03 FR-011, research/05 I-001 | Validate message structure before processing; contract violations detected early |
| **FR-010** | Python client library (PyPI) | MUST | research/03 FR-012, research/04 D-008 | Simple API: `validate(design_data)` returns result; handles HTTP/IPC transparently |
| **FR-011** | Concurrent validation via SCOOP | SHOULD | research/03 FR-013, research/04 D-007, research/05 I-006 | Each HTTP request runs in separate SCOOP processor; race-free validation |
| **FR-012** | Automatic retry and recovery (HTTP) | SHOULD | research/03 FR-014 | HTTP client retries on network failure; exponential backoff; max 3 retries |
| **FR-013** | Comprehensive logging integration | SHOULD | research/03 FR-015 | simple_logger integration; DEBUG level shows protocol details; ERROR level shows failures |
| **FR-014** | Manufacturing compliance metadata | SHOULD | research/05 I-003 | Messages include compliance_standard, requirement_id, test_case_id, audit trail |
| **FR-015** | Performance benchmarking | SHOULD | research/03 NFR-001 to NFR-006 | Measure and document latency, throughput for each bridge |

---

## Non-Functional Requirements

| ID | Requirement | Category | Measure | Target | Phase |
|----|-------------|----------|---------|--------|-------|
| **NFR-001** | HTTP latency (localhost) | PERFORMANCE | Round-trip time | <50ms | Phase 2 |
| **NFR-002** | IPC latency (localhost) | PERFORMANCE | Round-trip time | <5ms | Phase 2 |
| **NFR-003** | gRPC latency (localhost) | PERFORMANCE | Round-trip time | <20ms | Phase 2 |
| **NFR-004** | HTTP throughput | PERFORMANCE | Requests/second | ≥100/sec | Phase 2 |
| **NFR-005** | IPC throughput | PERFORMANCE | Requests/second | ≥1000/sec | Phase 2 |
| **NFR-006** | gRPC throughput | PERFORMANCE | Requests/second | ≥500/sec | Phase 2 |
| **NFR-007** | Message size (HTTP) | PERFORMANCE | Max JSON payload | ≤10 MB | Phase 2 |
| **NFR-008** | Message size (IPC) | PERFORMANCE | Max message | ≤1 MB | Phase 1 |
| **NFR-009** | Test coverage | QUALITY | Code coverage | ≥90% | Phase 1 |
| **NFR-010** | Test count | QUALITY | Passing tests | ≥100 | Phase 1 |
| **NFR-011** | Compilation warnings | QUALITY | Warnings | 0 (ZERO POLICY) | Phase 1 |
| **NFR-012** | Python compatibility | COMPATIBILITY | Python versions | 3.8, 3.9, 3.10, 3.11, 3.12 | Phase 2 |
| **NFR-013** | OS support | COMPATIBILITY | Platforms | Windows (primary), Linux (Phase 2) | Phase 1 |
| **NFR-014** | Eiffel version | COMPATIBILITY | EiffelStudio | 25.02+ | Phase 1 |
| **NFR-015** | SCOOP compatibility | ARCHITECTURE | Concurrency model | Race-free, no locks | Phase 1 |
| **NFR-016** | Contract coverage | ARCHITECTURE | Public interfaces | 100% | Phase 1 |
| **NFR-017** | Memory efficiency (HTTP) | PERFORMANCE | Per-request | <10 MB | Phase 2 |
| **NFR-018** | Memory efficiency (IPC) | PERFORMANCE | Per-request | <5 MB | Phase 2 |
| **NFR-019** | HTTP reliability | RELIABILITY | Uptime | 99.9% | Phase 2 |
| **NFR-020** | IPC reliability | RELIABILITY | Data loss | 0% (100% delivery) | Phase 1 |

---

## Domain-Specific Requirements (Manufacturing Validation)

| ID | Requirement | Category | Rationale | Phase |
|----|-------------|----------|-----------|-------|
| **MFR-001** | Support IEC 61131 validation | COMPLIANCE | Manufacturing standard for PLCs and control systems | Phase 2 |
| **MFR-002** | Support ISO 26262 traceability | COMPLIANCE | Automotive functional safety; requirement-to-test mapping | Phase 2 |
| **MFR-003** | Support FDA software validation | COMPLIANCE | Medical device manufacturing; audit trail, evidence retention | Phase 2 |
| **MFR-004** | Hardware-in-the-loop (HIL) integration | TESTING | Test embedded code against real control board hardware | Phase 2 |
| **MFR-005** | Real-time measurement capture | PERFORMANCE | Collect validation data without perturbing system under test | Phase 2 |
| **MFR-006** | Data integrity across boundaries | QUALITY | Message validation ensures no data corruption in transit | Phase 1 |
| **MFR-007** | Reproducible test execution | QUALITY | Same inputs always produce same results (deterministic validation) | Phase 1 |
| **MFR-008** | Audit trail (who/what/when) | COMPLIANCE | Manufacturing regulatory requirement; proof of validation | Phase 2 |
| **MFR-009** | Compliance metadata in messages | DESIGN | Requirement ID, test case ID, operator ID embedded in messages | Phase 1 |

---

## Constraints (Immutable - Eiffel Ecosystem Policy)

| ID | Constraint | Type | Immutable? | Rationale |
|----|-----------|------|-----------|-----------|
| **C-001** | Must be SCOOP-compatible | ARCHITECTURE | YES | Eiffel ecosystem standard; enables race-free concurrency |
| **C-002** | Must prefer simple_* over ISE | ECOSYSTEM | YES | simple_* first policy; use simple_http, simple_ipc, simple_json, not ISE equivalents |
| **C-003** | All public interfaces must have contracts | ARCHITECTURE | YES | Design by Contract philosophy; non-negotiable |
| **C-004** | Must compile to zero warnings | QUALITY | YES | Production code standard; no technical debt |
| **C-005** | HTTP bridge must use simple_http | DEPENDENCY | YES | Ecosystem compliance; proven in production |
| **C-006** | IPC bridge must use simple_ipc | DEPENDENCY | YES | Ecosystem compliance; Windows named pipes via simple_ipc |
| **C-007** | JSON serialization via simple_json | DEPENDENCY | YES | Schema validation advantage (Eiffel-unique); JSON RFC compliance |
| **C-008** | gRPC bridge must use simple_grpc | DEPENDENCY | YES | Protocol layer from simple_grpc; socket I/O TBD in Phase 2 |
| **C-009** | Void-safe code required | ARCHITECTURE | YES | All classes void-safe (detachable parameters checked, attributes safe) |

---

## Decisions Already Made (from Research)

| ID | Decision | Rationale | Source |
|----|----------|-----------|--------|
| **D-001** | Three protocols via ECF multi-target (HTTP, IPC, gRPC) | Manufacturing customers deploy to different environments; shared core prevents duplication | research/04 |
| **D-002** | Shared PYTHON_MESSAGE interface with protocol-specific serialization | Design by Contract requires shared contracts; serialization is pluggable | research/04 |
| **D-003** | Validation logic in Eiffel, orchestration in Python | Eiffel excels at high-assurance verification; Python valuable for ecosystem | research/04 |
| **D-004** | Protocol-specific serialization (JSON/HTTP, Binary/IPC, Protobuf/gRPC Phase 2) | Each format optimized for transport layer | research/04 |
| **D-005** | Defer gRPC + socket I/O to Phase 2 | Unblocks Phase 1; HTTP + IPC sufficient for MVP | research/04 |
| **D-006** | Per-protocol test fixtures (not shared test suite) | Each protocol needs different setup; reduces test coupling | research/04 |
| **D-007** | Use SCOOP concurrency with separate keyword | Race-free validation without explicit locks | research/04 |
| **D-008** | Provide Python client library (PyPI) | Lowers barrier to entry; 80-90% developers want simple API | research/04 |

---

## Innovations to Implement

| ID | Innovation | Design Impact | Phase |
|----|------------|---------------|----|
| **I-001** | Design by Contract as interface specification | Contracts become API contract; Python clients read preconditions as expected input | Phase 1 |
| **I-002** | Protocol-agnostic message semantics with deferred implementation | Change message schema once; all protocols inherit; 30-40% code reduction | Phase 1 |
| **I-003** | Manufacturing-focused message schema with compliance metadata | Requirement ID, test case ID, operator ID; audit trail built-in | Phase 1 |
| **I-004** | Streaming validation with incremental results (gRPC) | Client sees errors in real-time; scales to large designs | Phase 2 |
| **I-005** | Contract-based API generation (future) | Auto-generate OpenAPI, Pydantic, Python stubs from contracts | Phase 3 |
| **I-006** | SCOOP-safe concurrent validation without locks | Hundreds of concurrent validations, zero data races, no explicit synchronization | Phase 1 |

---

## Risks Identified (from Research - Key Risks Only)

| ID | Risk | Likelihood | Impact | Mitigation | Phase |
|----|------|-----------|--------|-----------|-------|
| **RISK-001** | Socket I/O library not available for gRPC Phase 1 | HIGH | MEDIUM | Defer gRPC to Phase 2; evaluate options early | Phase 1 |
| **RISK-004** | Performance not meeting manufacturing latency targets | MEDIUM | HIGH | Benchmark early; offer multiple targets (HTTP/IPC); optimize serialization | Phase 1-2 |
| **RISK-005** | Manufacturing compliance poorly understood | MEDIUM | HIGH | Domain expert consultation Phase 2; standards research | Phase 2 |
| **RISK-010** | Testing complexity overwhelming (3 protocols × scenarios) | MEDIUM | MEDIUM | Focus MVP on critical path; defer edge cases to Phase 2 | Phase 1 |

---

## Use Cases

### UC-001: Control Board Validation via HTTP (Cloud Integration)

**Actor:** Manufacturing engineer, cloud-based validation system

**Precondition:**
- Eiffel HTTP server running on cloud instance
- Python validation orchestration script has IP address and port

**Main Flow:**
1. Python script loads electronic design (schematic, firmware, netlist)
2. Constructs PYTHON_VALIDATION_REQUEST with design_data, rules_list, compliance_standard
3. HTTP POST to `/api/validate` with JSON payload
4. Eiffel server receives, validates preconditions (design not void, rules initialized)
5. Executes validation logic (Design by Contract contracts enforce verification)
6. Constructs PYTHON_VALIDATION_RESPONSE with errors, warnings, metadata
7. HTTP 200 returns JSON response
8. Python script parses response, generates report, stores evidence

**Postcondition:**
- Validation complete, errors logged, compliance metadata stored
- Evidence artifact URL points to stored validation record

**Alternative:** Network failure → HTTP client retries with exponential backoff

---

### UC-002: Same-Machine Real-Time Validation via IPC (Embedded Systems)

**Actor:** Embedded firmware engineer, hardware-in-the-loop test

**Precondition:**
- Eiffel IPC server listening on named pipe `\\.\pipe\eiffel_validator`
- Python test harness has pywin32 for named pipe access

**Main Flow:**
1. Hardware test triggers Python test case
2. Python constructs PYTHON_VALIDATION_REQUEST (design snippet, real-time measurements)
3. Named pipe client sends: [4-byte length][binary payload]
4. Eiffel server receives, validates preconditions
5. Validates design against measurements (real-time feedback)
6. Constructs PYTHON_VALIDATION_RESPONSE
7. Named pipe server sends: [4-byte length][response bytes]
8. Python test case reads response, updates hardware state if validation passes
9. Continues to next test

**Postcondition:**
- Real-time validation feedback drives test automation
- IPC <5ms latency enables tight control loop

**Alternative:** Named pipe broken → Error recovery with reconnection

---

### UC-003: Type-Safe RPC with Streaming (Future - gRPC Phase 2)

**Actor:** Cloud architect, real-time design validation with streaming

**Precondition:**
- Eiffel gRPC server with socket I/O operational
- Python gRPC client with generated stubs from .proto files

**Main Flow:**
1. Python opens bidirectional gRPC stream
2. Sends VALIDATE_REQUEST protobuf messages incrementally (large design chunks)
3. Eiffel server validates each chunk, streams back VALIDATE_RESPONSE immediately
4. Python client processes responses in real-time (fail-fast on first error)
5. Stream closes when validation complete

**Postcondition:**
- Large designs validated without full in-memory load
- Real-time feedback drives iterative validation

---

## Success Criteria (Phase 1 MVP)

- [ ] HTTP bridge working: Python `requests` library can POST to `/api/validate`
- [ ] IPC bridge working: Python named pipe client exchanges binary messages
- [ ] 100+ tests passing (≥90% coverage)
- [ ] Zero compilation warnings
- [ ] Design by Contract on 100% of public interfaces
- [ ] Documentation complete (README, API guide, examples)
- [ ] Python client library published (PyPI)

---

## Next Steps

**Proceed to Step 2:** DOMAIN-MODEL.md - Identify domain concepts and class structure
