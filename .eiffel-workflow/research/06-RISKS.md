# RISKS: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Research Phase:** Step 6 - Identify and Mitigate Risks

---

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Contingency |
|----|------|-----------|--------|-----------|------------|
| RISK-001 | gRPC socket I/O library not available Phase 1 | HIGH | MEDIUM | Defer gRPC to Phase 2; deliver HTTP+IPC MVP | Use simple_process delegation |
| RISK-002 | Python developers unfamiliar with Design by Contract | MEDIUM | LOW | Comprehensive documentation with examples | Provide contract checklists, templates |
| RISK-003 | IPC (named pipes) Windows-only limitation | MEDIUM | MEDIUM | Document Windows requirement; note future Linux work | Recommend HTTP for multi-platform deployments |
| RISK-004 | Performance not meeting manufacturing latency requirements | MEDIUM | HIGH | Benchmark early; optimize serialization | Offer multiple target options (choose fastest) |
| RISK-005 | Manufacturing compliance frameworks poorly understood | MEDIUM | HIGH | Research IEC 61131, ISO 26262, IEC 62304 early | Hire manufacturing domain expert consultant |
| RISK-006 | SCOOP concurrency model not understood by Python teams | MEDIUM | LOW | Provide SCOOP abstractions; hide complexity | Documentation, training materials |
| RISK-007 | simple_json schema validation inadequate for complex designs | LOW | MEDIUM | Early validation with manufacturing schemas | Fall back to Protocol Buffers for gRPC |
| RISK-008 | Eiffel-to-Python ecosystem gap (Python has more libraries) | LOW | LOW | Acknowledge Eiffel strength (contracts, verification) | Position Eiffel as validation layer, not replacement |
| RISK-009 | Customer wants feature not in scope (CAN bus, OPC-UA, etc.) | MEDIUM | MEDIUM | Clear scope boundaries in documentation | Provide extension points for future integrations |
| RISK-010 | Testing complexity overwhelms schedule (3 protocols × many scenarios) | MEDIUM | MEDIUM | Focus MVP tests on core path; defer edge cases | Reduce test count for Phase 1; add Phase 2 |
| RISK-011 | Eiffel compilation issues on customer systems | LOW | MEDIUM | Provide Docker containers pre-compiled | Detailed troubleshooting guide, support channels |
| RISK-012 | Python version compatibility issues | LOW | MEDIUM | Test against Python 3.8, 3.9, 3.10, 3.11, 3.12 | Maintain compatibility matrix, clear guidance |
| RISK-013 | Manufacturing standards evolve (IEC 61131-4, -5, etc.) | LOW | LOW | Build extensibility for future standards | Modular design, dataclass-based standards support |

---

## Technical Risks

### RISK-001: Socket I/O Library Not Available (Phase 1)

**Description:**
simple_grpc provides Protocol Buffers + HTTP/2 framing, but lacks socket I/O. No simple_socket library exists. gRPC bridge blocked unless socket I/O resolved.

**Likelihood:** HIGH
**Impact:** MEDIUM (blocks gRPC, but HTTP+IPC sufficient for MVP)

**Indicators:**
- Attempt to implement GRPC_BRIDGE discovers socket layer needed
- simple_grpc documentation mentions "requires socket library"

**Mitigation:**
1. **Defer gRPC to Phase 2** (chosen approach for MVP)
2. Research socket options early (build, wrap ISE, delegate)
3. Validate chosen approach before Phase 2 starts
4. Build simple_socket library if necessary (separate project)

**Contingency:**
- Use simple_process delegation: Eiffel calls Python subprocess for gRPC socket I/O
- Reduces gRPC performance but enables Phase 1 completion

**Owner:** Architecture

---

### RISK-004: Performance Not Meeting Requirements

**Description:**
Manufacturing validation latency-sensitive. HTTP 50ms, IPC <5ms targets may not achieve with current design.

**Likelihood:** MEDIUM
**Impact:** HIGH (performance regression = customer unhappy)

**Indicators:**
- Benchmarking shows HTTP >100ms latency
- IPC shows >20ms (overhead from message serialization)

**Mitigation:**
1. Benchmark early (Phase 1, week 1)
2. Profile hot paths (JSON serialization, IPC framing)
3. Optimize serialization (Protocol Buffers for HTTP vs JSON)
4. Offer multiple targets (customers choose HTTP/IPC based on performance needs)
5. Document performance characteristics per target

**Contingency:**
- Fall back to binary Protocol Buffers for HTTP (sacrifices JSON simplicity)
- Use async HTTP (requests batch validation calls)
- Optimize IPC framing (reduce message overhead)

**Owner:** Performance Engineering

---

### RISK-007: JSON Schema Validation Inadequate

**Description:**
simple_json JSON Schema is powerful but may not cover all manufacturing design validation requirements.

**Likelihood:** LOW
**Impact:** MEDIUM (forces fallback to Protocol Buffers for HTTP)

**Indicators:**
- Manufacturing schemas use custom validation rules
- JSON Schema insufficient for electrical design constraints

**Mitigation:**
1. Validate with manufacturing customer early
2. Test typical design schemas against JSON Schema
3. Extend JSON Schema with custom validators in Eiffel (business logic)
4. Document JSON Schema limitations

**Contingency:**
- Fall back to Protocol Buffers for HTTP (eliminates JSON, loses simplicity)
- Use Eiffel contracts for complex validation (not JSON Schema)
- Provide custom validators in bridge (Eiffel-side business logic)

**Owner:** Requirements

---

## Ecosystem Risks

### RISK-003: IPC Windows-Only Limitation

**Description:**
simple_ipc uses Windows named pipes. Linux support stub only. Customers on Linux/macOS can't use IPC bridge.

**Likelihood:** MEDIUM
**Impact:** MEDIUM (limits deployment options, but HTTP available)

**Indicators:**
- Customer requests Linux IPC support
- Named pipes not available on Linux

**Mitigation:**
1. Document Windows requirement for IPC target clearly
2. Recommend HTTP for multi-platform deployments
3. Note future Linux IPC implementation (Unix domain sockets)
4. Test IPC on Windows thoroughly

**Contingency:**
- Implement Linux Unix domain sockets in Phase 2
- Fall back to HTTP for Linux customers
- Provide Docker containers (avoid platform dependencies)

**Owner:** Platform Support

---

### RISK-008: Eiffel-to-Python Ecosystem Gap

**Description:**
Python has vastly larger ecosystem than Eiffel. Customers expecting all functionality in Eiffel unavailable.

**Likelihood:** LOW
**Impact:** LOW (expected and documented)

**Indicators:**
- Customer asks "why isn't X in Eiffel?"
- Requests for Python library features

**Mitigation:**
1. Position Eiffel as validation layer (high-assurance domain)
2. Position Python as orchestration/analysis layer (rich ecosystem)
3. Clear separation of concerns in architecture
4. Documentation explaining what each language is good at

**Contingency:**
- Accept limitation; recommend Python for extended functionality
- Build Eiffel feature only if core to validation

**Owner:** Product Management

---

## Compliance Risks

### RISK-005: Manufacturing Compliance Frameworks Poorly Understood

**Description:**
IEC 61131, ISO 26262, IEC 62304 are complex standards. Insufficient understanding leads to bridge that doesn't meet manufacturing needs.

**Likelihood:** MEDIUM
**Impact:** HIGH (bridge deployed non-compliant, customer liability)

**Indicators:**
- Early manufacturing customer feedback: "Doesn't meet our IEC 61131 validation process"
- Audit failures due to missing evidence artifacts

**Mitigation:**
1. Research standards early (Phase 0, before design)
2. Consult manufacturing domain expert (early review)
3. Include compliance metadata in message design
4. Test with manufacturing customer pilots early
5. Build compliance evidence collection into bridge

**Contingency:**
- Hire manufacturing compliance consultant for Phase 2
- Implement compliance framework add-on (separate module)
- Provide compliance audit trail (evidence artifact storage)

**Owner:** Requirements + Quality Assurance

---

## Resource Risks

### RISK-010: Testing Complexity Overwhelms Schedule

**Description:**
Three independent protocol bridges × multiple test scenarios = test explosion. Test suite grows unmanageable.

**Likelihood:** MEDIUM
**Impact:** MEDIUM (slips schedule, reduces coverage)

**Indicators:**
- Test suite grows >200 tests (difficult to maintain)
- Test execution time >10 minutes (CI/CD delays)
- Test failures due to test harness bugs (not product bugs)

**Mitigation:**
1. Focus MVP tests on critical path (happy path, error cases)
2. Defer edge cases to Phase 2
3. Use per-protocol fixtures (not shared, reduces test complexity)
4. Implement test helpers (reduce test code duplication)
5. Target 100+ tests, not 500+

**Contingency:**
- Reduce scope for Phase 1 (HTTP + IPC only, defer gRPC)
- Prioritize tests (critical → nice-to-have)
- Implement test selection (run subset for rapid iteration)

**Owner:** QA/Testing

---

## Operational Risks

### RISK-011: Eiffel Compilation Issues on Customer Systems

**Description:**
Customers attempt to compile simple_python on their machines; compilation fails due to missing EiffelStudio, library paths, build tools.

**Likelihood:** LOW
**Impact:** MEDIUM (customer can't deploy)

**Indicators:**
- Customer reports compilation failure
- EiffelStudio not installed on customer system

**Mitigation:**
1. Provide Docker containers (pre-compiled binaries)
2. Provide Windows installers (MSI packages)
3. Detailed setup documentation
4. Troubleshooting guide for common issues
5. Offer pre-built HTTP/IPC servers (ready-to-deploy)

**Contingency:**
- Provide source code + detailed build instructions
- Offer compilation as-a-service (cloud-based builds)
- Support channel for troubleshooting

**Owner:** DevOps/Release Engineering

---

### RISK-012: Python Version Compatibility Issues

**Description:**
Python ecosystem fragmented (3.8, 3.9, 3.10, 3.11, 3.12, 3.13). Bridge works on one version, breaks on another.

**Likelihood:** LOW
**Impact:** MEDIUM (customer stuck on older Python)

**Indicators:**
- Customer reports "doesn't work with Python 3.8"
- CI/CD tests pass on 3.12, fail on 3.8

**Mitigation:**
1. Test against multiple Python versions (3.8, 3.9, 3.10, 3.11, 3.12)
2. Use compatibility shims (six, future) if necessary
3. Publish compatibility matrix clearly
4. Use pyenv/Docker to test locally
5. CI/CD matrix testing (GitHub Actions)

**Contingency:**
- Support only LTS Python versions (3.8, 3.10, 3.12)
- Recommend Python 3.11+ for new deployments
- Provide version-specific wheels

**Owner:** Build/CI-CD

---

## Risk Mitigation Summary

| Risk Type | Mitigation Strategy |
|-----------|-------------------|
| **Technical** | Early benchmarking, iterative testing, alternative approaches ready |
| **Ecosystem** | Clear scope, separation of concerns, document limitations |
| **Compliance** | Domain expert consultation, standards research, audit trail built-in |
| **Resource** | Focused scope, test prioritization, MVP mindset |
| **Operational** | Docker containers, pre-built binaries, comprehensive documentation |

---

## Risk Monitoring

**Phase 1 (MVP):**
- Weekly risk review
- RISK-001 (socket I/O): Confirm gRPC deferred decision OK
- RISK-004 (performance): Benchmark complete by Week 2
- RISK-005 (compliance): Confirm manufacturing standards understood

**Phase 2 (gRPC):**
- RISK-001 resolved (socket I/O approach chosen)
- RISK-003 (IPC Windows) revisited (Linux support planned?)
- RISK-005 (compliance) extended (complete frameworks documented)

---

## Next Steps

Proceed to Step 7: RECOMMENDATION - Final direction based on research.
