# SCOPE: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Research Phase:** Step 1 - Define Boundaries

---

## Problem Statement

**In one sentence:** Industrial manufacturers need a production-grade way to integrate Python (analysis, orchestration, visualization, hardware control) with Eiffel (high-assurance validation, DBC contracts, embedded code verification) for control board and embedded system validation.

### What's Wrong Today

- **Integration Complexity:** No unified bridge exists between Eiffel and Python for manufacturing validation workflows
- **Manual Integration:** Each integration requires custom FFI bindings, error handling, serialization logic
- **Validation Gaps:** Python lacks Eiffel's Design by Contract guarantees; Eiffel lacks Python's ecosystem
- **Manufacturing Pain Points:**
  - ERP/MES/SCADA systems don't communicate effectively
  - Data accuracy issues across system boundaries
  - Validation requirements scattered across multiple tools
  - Legacy systems lagging on IIoT and cloud integration
  - Testing frameworks not integrated with validation logic

### Who Experiences This

1. **Control Board Manufacturers** - Validate PCB designs, embedded code, firmware
2. **Manufacturing Engineers** - Integrate validation systems with ERP/MES/SCADA
3. **Embedded Systems Developers** - Build firmware with high-assurance contracts
4. **QA/Test Engineers** - Automate hardware-software integration testing
5. **Systems Integrators** - Connect heterogeneous manufacturing systems

### Impact of Not Solving

- Continued use of ad-hoc integration scripts (unmaintainable)
- Data integrity issues across system boundaries (compliance risk)
- Testing gaps between design validation and production deployment
- Inability to leverage Eiffel's contract-based guarantees in Python workflows
- Limited deployment flexibility (one-size-fits-all integration)

---

## Target Users

| User Type | Needs | Pain Level |
|-----------|-------|------------|
| Control Board Manufacturers | Validate designs (electrical, firmware, embedded code) with high assurance; integrate validation results with manufacturing data | **HIGH** |
| Manufacturing Systems Integrators | Bridge ERP/MES/SCADA/PLC systems; ensure data consistency across layers | **HIGH** |
| Embedded Firmware Engineers | Write safety-critical code with Design by Contract; verify behavior before deployment | **HIGH** |
| QA/Test Engineers | Automate hardware-in-the-loop testing; collect real-time validation data | **MEDIUM** |
| DevOps/Cloud Architects | Deploy validation systems across cloud or edge; orchestrate validation workflows | **MEDIUM** |
| Data Analysts | Analyze validation results, detect patterns, drive continuous improvement | **MEDIUM** |

---

## Success Criteria

### MVP (Minimum Viable Product)
| Criterion | Measure |
|-----------|---------|
| Three independent bridge implementations (HTTP, IPC, gRPC) | All three targets compile, zero warnings |
| Design-by-Contract contracts on all public interfaces | 100% of public classes have preconditions, postconditions, invariants |
| Python interoperability proven | Python scripts call Eiffel validators via all three bridges |
| Message validation contracts | JSON Schema validation (HTTP), Protocol Buffers schema (gRPC) |
| Comprehensive test suite | ≥100 tests, ≥90% code coverage, all passing |
| Documentation and examples | README, usage examples, architecture guide |

### Full (Production-Grade)
| Criterion | Measure |
|-----------|---------|
| Performance | HTTP <50ms latency (localhost), IPC <5ms, gRPC <20ms |
| Reliability | 99.9% uptime in manufacturing simulation; automatic retry/recovery |
| Safety | Supports IEC 61131, ISO 26262, IEC 62304 compliance frameworks |
| Scalability | Handles 1000+ messages/second, multi-threaded/SCOOP concurrent |
| Cloud-ready | Deployable as containerized service; gRPC streaming support |
| Ecosystem integration | Works with simple_json (validation), simple_docker (orchestration), simple_logger (diagnostics) |

---

## Scope Boundaries

### In Scope (MUST HAVE)

**Core Bridges:**
- HTTP REST bridge (simple_http + simple_json)
- IPC bridge (simple_ipc, Windows named pipes)
- gRPC bridge (simple_grpc + Protocol Buffers)

**Shared Foundation:**
- PYTHON_BRIDGE interface (deferred contracts)
- PYTHON_MESSAGE base class (serialization)
- Error handling and recovery
- Design by Contract on all public interfaces

**Testing:**
- Unit tests for message contracts
- Integration tests for all three bridges
- Python interoperability tests
- Setup/teardown per protocol variant

**Documentation:**
- Architecture guide
- Usage examples (HTTP, IPC, gRPC)
- Python client examples
- Deployment guide

### In Scope (SHOULD HAVE)

**Quality & Safety:**
- 100% test coverage for core classes
- Compliance checklist (IEC 61131, ISO 26262, IEC 62304)
- Performance benchmarks
- Security best practices (authentication, encryption options)

**Advanced Features:**
- Automatic retry with exponential backoff (HTTP)
- Circuit breaker pattern (HTTP)
- Message compression options
- Bulk message handling
- Streaming RPC (gRPC bidirectional)

**Ecosystem Integration:**
- Integration with simple_logger (structured logging)
- Integration with simple_docker (containerization examples)
- Integration with simple_mq (message queuing)

### Out of Scope

**These are intentionally deferred:**

| Feature | Reason |
|---------|--------|
| TLS/Encryption | Phase 2; use platform-level HTTPS/mTLS initially |
| Load balancing | Phase 2; handled by infrastructure (nginx, Kubernetes) |
| Java interoperability | Future; focus on Python first |
| Dynamic Protocol Selection | Phase 2; customer chooses target at deployment |
| Custom Serialization Formats | Protocol Buffers + JSON sufficient for 80% of use cases |
| GUI/Visualization | Python responsibility; Eiffel provides REST API backend |

### Deferred to Future

| Item | Reason |
|------|--------|
| simple_socket library (if needed for gRPC) | May use simple_process delegation instead |
| CAN Bus integration | Future simple_can library |
| Blockchain/Distributed Ledger | Beyond manufacturing validation scope |
| Machine Learning inference | Python ecosystem handles this; bridge provides data |

---

## Constraints

### Technical Constraints (Immutable)

| Constraint | Why | Impact |
|-----------|-----|--------|
| Must be SCOOP-compatible | Eiffel ecosystem standard | Design for concurrent message handling |
| Must prefer simple_* over ISE | Eiffel ecosystem policy | Use simple_http, simple_ipc, simple_grpc, not ISE wrappers |
| Must compile to C | Eiffel architecture | Enables CFFI binding for Python integration |
| Must support Windows + Linux | Manufacturing deployments | Named pipes (Windows), sockets (both) |
| Design by Contract mandatory | Eiffel philosophy | All public interfaces have contracts |

### Resource Constraints

| Constraint | Impact |
|-----------|--------|
| Single developer focus | Prioritize HTTP + IPC for MVP; gRPC as Phase 2 if socket I/O needed |
| 4000-4500 LOC/day productivity | 4-5 day sprint for complete MVP |
| No external socket library (yet) | Evaluate gRPC approach (Protocol Buffers only, or delegate socket I/O) |

### Ecosystem Constraints

| Constraint | Impact |
|-----------|--------|
| simple_grpc is beta | Use for protocol layer only; socket I/O TBD |
| ISE/EiffelStudio 25.02 | Latest IDE required; modern SCOOP support |
| Python 3.8+ | Standard library features; no legacy Python 2 |

---

## Assumptions to Validate

| ID | Assumption | Risk if False | Research Evidence |
|----|-----------|---------------|-------------------|
| A-1 | Python HTTP clients can integrate with Eiffel HTTP servers | **LOW** | Proven pattern (simple_web works with any HTTP client) |
| A-2 | Named pipes (IPC) are sufficient for same-machine validation | **MEDIUM** | Windows manufacturing environments common; Linux less common |
| A-3 | Protocol Buffers is the right serialization for control boards | **LOW** | Industry standard for type-safe industrial systems; gRPC recommended |
| A-4 | Manufacturing customers want flexible deployment (3 targets) | **MEDIUM** | Assumption: different customers prefer different transport layers |
| A-5 | Design by Contract resonates with manufacturing validation | **LOW** | Eiffel-Loop experience shows contracts valuable for reliable systems |
| A-6 | 80% of use cases fit HTTP + IPC + gRPC patterns | **MEDIUM** | May be use cases requiring CAN bus, OPC-UA, or other protocols |
| A-7 | Eiffel's SCOOP sufficient for concurrent validation | **LOW** | SCOOP proven in production systems; no synchronization needed |
| A-8 | Python developers can use simple_* libraries | **LOW** | Bridges present Python objects/functions as normal Python calls |

---

## Research Questions

These questions drive investigation in Steps 2-3:

### Problem Validation
- How do manufacturing systems currently validate control boards? What's the current pain?
- What does a typical validation workflow look like (design → test → production)?
- What data must cross the Eiffel-Python boundary? Size? Frequency? Format?

### Technology Selection
- Is gRPC necessary for manufacturing validation, or is HTTP sufficient for MVP?
- Do customers prefer FFI-style direct calls or message-based RPC?
- What serialization formats are customers already using?

### Integration Patterns
- How do ERP/MES/SCADA systems expect data (REST API? Message queue? Direct database)?
- What are the performance requirements (real-time? batch? interactive)?
- How important is cloud deployment vs. on-premises?

### Safety & Compliance
- Which standards apply? IEC 61131? ISO 26262? IEC 62304?
- What validation evidence must be collected and retained?
- How important is cryptographic audit trails?

### Ecosystem Alignment
- Will simple_socket be needed, or can we work around it?
- Should socket I/O be built as separate library, or embedded in simple_python?
- Which simple_* libraries should simple_python depend on?

---

## Next Step

**Proceed to Step 2: LANDSCAPE** - Survey existing solutions, competitive analysis, Eiffel ecosystem assessment.
