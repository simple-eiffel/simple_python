# REQUIREMENTS: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Research Phase:** Step 3 - Define Needs

---

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | Three independent bridge implementations | MUST | HTTP, IPC, gRPC targets all compile, zero warnings |
| FR-002 | HTTP REST bridge for remote Python clients | MUST | Python `requests` library can POST/GET to validate endpoint |
| FR-003 | IPC named pipe bridge for same-machine validation | MUST | Python named pipe client exchanges messages with Eiffel server |
| FR-004 | gRPC bridge for type-safe RPC | SHOULD | Python gRPC client calls Eiffel gRPC service (Phase 2 if socket I/O needed) |
| FR-005 | Design by Contract on all public classes | MUST | 100% of public classes have preconditions, postconditions, invariants |
| FR-006 | Shared message interface (PYTHON_MESSAGE) | MUST | HTTP, IPC, gRPC all inherit from PYTHON_MESSAGE, implement serialization |
| FR-007 | Request-response message semantics | MUST | Validation request (design data) → Eiffel validates → response (errors/warnings) |
| FR-008 | JSON serialization for HTTP | MUST | Messages → JSON (HTTP requests), JSON → Messages (HTTP responses) |
| FR-009 | Protocol Buffers schema support | SHOULD | gRPC messages defined via .proto files, auto-generate Python stubs |
| FR-010 | Error handling and status codes | MUST | HTTP status codes (200, 400, 500), error messages in response payload |
| FR-011 | Message validation contracts | MUST | Validate message structure matches schema before processing |
| FR-012 | Python client library (easy API) | MUST | `from simple_python import validate; result = validate(design_data)` |
| FR-013 | Support concurrent validation requests | SHOULD | SCOOP enables multiple threads to validate simultaneously |
| FR-014 | Automatic retry and recovery | SHOULD | HTTP bridge retries on network failure; graceful degradation |
| FR-015 | Comprehensive logging and diagnostics | SHOULD | simple_logger integration for troubleshooting |

---

## Non-Functional Requirements

| ID | Requirement | Category | Measure | Target |
|----|-------------|----------|---------|--------|
| NFR-001 | HTTP latency (localhost) | PERFORMANCE | Round-trip time | <50ms |
| NFR-002 | IPC latency (localhost) | PERFORMANCE | Round-trip time | <5ms |
| NFR-003 | gRPC latency (localhost) | PERFORMANCE | Round-trip time | <20ms |
| NFR-004 | Throughput (HTTP) | PERFORMANCE | Requests/second | ≥100/sec |
| NFR-005 | Throughput (IPC) | PERFORMANCE | Requests/second | ≥1000/sec |
| NFR-006 | Throughput (gRPC) | PERFORMANCE | Requests/second | ≥500/sec |
| NFR-007 | Message size (HTTP) | PERFORMANCE | Max JSON payload | ≤10 MB |
| NFR-008 | Message size (IPC) | PERFORMANCE | Max message | ≤1 MB (named pipe limit) |
| NFR-009 | Test coverage | QUALITY | Code coverage | ≥90% |
| NFR-010 | Test count | QUALITY | Passing tests | ≥100 |
| NFR-011 | Compilation warnings | QUALITY | Warnings | 0 (zero policy) |
| NFR-012 | Python version support | COMPATIBILITY | Python versions | 3.8, 3.9, 3.10, 3.11, 3.12 |
| NFR-013 | Operating system support | COMPATIBILITY | OS platforms | Windows (primary), Linux (secondary) |
| NFR-014 | Eiffel version | COMPATIBILITY | EiffelStudio | 25.02+ |
| NFR-015 | SCOOP compatibility | ARCHITECTURE | Concurrency model | Race-free concurrent validation |
| NFR-016 | Design by Contract | ARCHITECTURE | Contract coverage | 100% of public interfaces |
| NFR-017 | Memory efficiency (HTTP) | PERFORMANCE | Per-request memory | <10 MB |
| NFR-018 | Memory efficiency (IPC) | PERFORMANCE | Per-request memory | <5 MB |
| NFR-019 | Reliability (HTTP) | RELIABILITY | Uptime | 99.9% (manufacturing simulation) |
| NFR-020 | Reliability (IPC) | RELIABILITY | Zero data loss | 100% message delivery (Windows pipes) |

---

## Domain-Specific Requirements (Manufacturing Validation)

| ID | Requirement | Category | Rationale |
|----|-------------|----------|-----------|
| MFR-001 | Support IEC 61131 validation | COMPLIANCE | Manufacturing standard for PLCs |
| MFR-002 | Support ISO 26262 traceability | COMPLIANCE | Automotive safety standard |
| MFR-003 | Support FDA software validation | COMPLIANCE | Medical device manufacturing |
| MFR-004 | Hardware-in-the-loop (HIL) integration | TESTING | Test embedded code against real hardware |
| MFR-005 | CAN bus message validation | INTEGRATION | Industrial control communication protocol |
| MFR-006 | Real-time measurement capture | PERFORMANCE | Collect data without perturbing system |
| MFR-007 | Data integrity across boundaries | QUALITY | Message validation ensures no corruption |
| MFR-008 | Reproducible test execution | QUALITY | Same inputs always produce same results |
| MFR-009 | Audit trail (who/what/when) | COMPLIANCE | Manufacturing regulatory requirement |

---

## Constraints

### Technical Constraints (Immutable)

| ID | Constraint | Type | Immutable? | Rationale |
|----|-----------|------|-----------|-----------|
| C-001 | Must be SCOOP-compatible | ARCHITECTURE | YES | Eiffel ecosystem standard |
| C-002 | Must prefer simple_* over ISE | ECOSYSTEM | YES | Library selection policy |
| C-003 | All public interfaces must have contracts | ARCHITECTURE | YES | Design by Contract philosophy |
| C-004 | Must compile to zero warnings | QUALITY | YES | Production code standard |
| C-005 | HTTP bridge must use simple_http | DEPENDENCY | YES | Leverage existing library |
| C-006 | IPC bridge must use simple_ipc | DEPENDENCY | YES | Leverage existing library |
| C-007 | JSON serialization must use simple_json | DEPENDENCY | YES | JSON Schema validation |
| C-008 | gRPC bridge must use simple_grpc | DEPENDENCY | YES | Protocol Buffers standard |
| C-009 | Must support Windows + Linux | DEPLOYMENT | NO (Windows primary) | Manufacturing environments |

---

## Safety & Compliance Requirements

| Standard | Requirement | Implementation |
|----------|------------|-----------------|
| **IEC 61131** | PLC validation framework | Protocol support for control system tests |
| **ISO 26262** | Functional safety for automotive | Traceability matrix, requirement coverage |
| **IEC 62304** | Medical device software | Design documents, verification evidence |
| **FDA GAMP 5** | Software validation | Risk-based requirements, test protocols |

---

## Success Metrics

### MVP Success
- [ ] All three targets compile, zero warnings
- [ ] Python script successfully validates design via HTTP
- [ ] Python script successfully validates design via IPC
- [ ] Test suite passes 100+ tests
- [ ] Documentation complete with examples

### Production Success
- [ ] gRPC bridge operational (socket I/O resolved)
- [ ] Performance benchmarks achieved (latency, throughput)
- [ ] 90%+ test coverage
- [ ] Manufacturing customer pilots successful
- [ ] GitHub repository public, community engaged

---

## Next Steps

Proceed to Step 4: DECISIONS - Resolve architectural choices based on requirements.
