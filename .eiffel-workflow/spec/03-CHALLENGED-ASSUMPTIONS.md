# CHALLENGED ASSUMPTIONS: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Specification Phase:** Step 3 - Attack Assumptions and Identify Gaps

---

## Overview

This document challenges every assumption from the research phase and prior planning. The goal is to identify:
- Assumptions that may be incorrect or incomplete
- Requirements that were missed during research
- Design constraints that deserve deeper scrutiny
- Opportunities for innovation beyond the initial concept

---

## Research Assumptions - Challenged

### A-001: "Manufacturing Validation is the Primary Use Case"

**Assumption from research:** simple_python targets manufacturing validation systems (control boards, embedded code verification). This is THE market fit.

**Challenge:**
- How do we know this is the primary use case?
- Are there other Python-Eiffel integration scenarios?
- What if manufacturing is only 20% of actual demand?

**Evidence FOR:**
- Research consulted 7 manufacturing-specific resources (IEC 61131, ISO 26262, IEC 62304 standards)
- Customer personas identified: control board manufacturers, systems integrators, firmware engineers
- Manufacturing validation pain points clearly documented from internet forums
- IEC/ISO standards explicitly require audit trails and traceability
- Simple_python research emphasized manufacturing compliance as Phase 2 innovation

**Evidence AGAINST:**
- No direct customer interviews (market research was secondary sources)
- Assumption not validated with actual manufacturing customers
- Other markets (data science, simulation, scientific computing) also use Python-Eiffel bridges
- Simple_* ecosystem is broad; manufacturing is one of many domains

**Verdict:** VALID but INCOMPLETE
- Keep manufacturing as primary persona
- But design architecture flexible enough for non-manufacturing use cases (universities, research labs)
- Message type hierarchy should not mandate manufacturing fields
- Phase 1 includes manufacturing metadata fields but doesn't require them

**Action:**
- Design PYTHON_REQUEST/PYTHON_RESPONSE with optional manufacturing_metadata (not required)
- Treat manufacturing compliance as Phase 2 extension, not Phase 1 requirement
- Allow simple validators that don't care about audit trails

---

### A-002: "Three Independent Protocols is the Right Architecture"

**Assumption from research:** Single codebase with three protocol targets (HTTP, IPC, gRPC) via ECF multi-target architecture is optimal.

**Challenge:**
- Is this actually easier than three separate libraries?
- Does shared code really prevent drift or does it create coupling?
- What happens when Python needs a feature only HTTP can deliver?

**Evidence FOR:**
- ECF multi-target architecture designed exactly for this pattern
- Shared bridge interface ensures code reuse of validation logic
- Message contracts defined once, inherited by all three
- Research explicitly cited "30-40% code reduction" from protocol-agnostic messages
- No compilation warnings policy forces all three targets to compile together
- Test suite validates all three simultaneously

**Evidence AGAINST:**
- Customers might prefer specialized libraries (HTTP-only, IPC-only)
- Maintenance burden: must support all three even if customer only uses one
- Complexity for library users who just want HTTP
- Risk: one protocol's update breaks the others (shared code)

**Verdict:** VALID with CAVEATS
- Three targets architecture is sound and justified
- But distribution strategy should allow:
  - Full library (all three targets)
  - HTTP-only distribution (for cloud-only customers)
  - IPC-only distribution (for embedded-only customers)
- ECF can express this via optional clustering

**Action:**
- Keep multi-target architecture as designed
- Document that all three must compile for released version
- Plan post-v1.0 optional distribution variants
- Ensure message contracts don't mandate protocol-specific fields

---

### A-003: "HTTP Bridge is Most Mature, Should Come First"

**Assumption from research:** HTTP bridge (Phase 2 in plan) is the most production-proven and should be implemented first.

**Challenge:**
- Is HTTP really simpler than IPC?
- Does simple_json + simple_web maturity guarantee HTTP bridge simplicity?
- What if JSON serialization becomes the bottleneck?

**Evidence FOR:**
- simple_http v1.0.0 production release
- simple_web v1.0.0 production release
- simple_json v1.0.0 with 100% test coverage
- 80% of industry uses HTTP REST (market validation)
- JSON Schema validation adds type safety

**Evidence AGAINST:**
- HTTP client retries, timeouts, error handling add complexity
- JSON serialization has overhead vs binary IPC
- Network latency even on localhost
- No simple_http streaming (gRPC more natural for streaming)

**Verdict:** VALID
- HTTP is the right first bridge to implement
- Provides immediate value to cloud customers
- Simpler than gRPC (no socket I/O blocker)
- IPC follows naturally as optimization layer

**Action:**
- Keep Phase 2 HTTP implementation as planned
- But note performance alternatives in documentation
- Consider JSON vs Protocol Buffers decision only for gRPC

---

### A-004: "IPC Named Pipes is Windows-Only, Accept This Limitation"

**Assumption from research:** IPC bridge uses Windows named pipes; Linux support deferred to Phase 2.

**Challenge:**
- Are we locking out Linux customers unnecessarily?
- Should we use Unix domain sockets instead of named pipes for cross-platform support?
- What percentage of manufacturing validation actually runs on Windows?

**Evidence FOR:**
- Research identified named pipes as Windows-specific limitation
- Unix domain sockets (SOCK_STREAM) are functional equivalent on Linux/macOS
- Phase 2 deferred work explicitly includes "Unix domain sockets"
- Windows primary for MVP (research confirmed)

**Evidence AGAINST:**
- Manufacturing increasingly using Linux for edge devices
- Cloud deployments heavily Linux-based
- Eiffel community mostly uses Windows? Verify this assumption.
- simple_ipc might already support Unix domain sockets (VERIFY)

**Verdict:** NEEDS_VALIDATION
- Check simple_ipc documentation for Unix domain socket support
- If already supported, implement for both Windows/Linux in Phase 1
- If not, Phase 2 deferred is acceptable for MVP

**Action:**
- Query oracle: "Does simple_ipc support Unix domain sockets in addition to Windows named pipes?"
- If yes: Extend Phase 1 to include Unix domain sockets (minimal effort)
- If no: Keep Windows-only for Phase 1, document Linux path for Phase 2

---

### A-005: "gRPC Implementation Approach - Design Choice"

**Status:** NOT a blocker. ISE NET library provides production-ready `NETWORK_STREAM_SOCKET`.

**Verified Fact:** ISE EiffelStudio 25.02 includes the `net.ecf` library with:
- `NETWORK_STREAM_SOCKET` class for TCP client/server sockets
- Full IPv4/IPv6 support, blocking/non-blocking modes, event-driven polling
- Maintained by ISE, used internally by HTTP client libraries
- SCOOP-compatible and void-safe

**Verdict:** NOT a blocker. The decision is architectural: which approach fits best?

**Three Implementation Approaches (Choose One):**

**Option A: Use ISE NET Library Directly (Fastest, lowest friction)**
- Use ISE's `NETWORK_STREAM_SOCKET` from `net.ecf` directly
- Effort: 1-2 days (gRPC bridge implementation only)
- Benefits:
  - Zero days building socket layer (already proven, maintained)
  - Simple, direct integration
  - ISE handles all socket complexity
- Drawback:
  - Not contributing to simple_* ecosystem
  - Ties gRPC bridge to ISE's socket API (acceptable, but not ecosystem-first)
- Path: Start GRPC_PYTHON_BRIDGE immediately using `NETWORK_STREAM_SOCKET`

**Option B: Build simple_socket Wrapper (Ecosystem-first, more effort)**
- Create new simple_socket library wrapping `NETWORK_STREAM_SOCKET` from ISE NET
- Effort: 2-3 days (socket wrapper) + 1-2 days (gRPC bridge) = 3-5 days total
- Benefits:
  - Long-term ecosystem value (other libraries can use it)
  - Follows simple_* pattern consistency
  - Eiffel ecosystem controls socket abstraction
  - Future Phase 2 protocols (streaming, async) built on simple_socket
- Drawback:
  - Slower initial delivery (adds 2-3 days)
  - Adds new library to maintain
- Path: Build simple_socket first (standalone library), then GRPC_PYTHON_BRIDGE

**Option C: Delegate to Python subprocess (Maximum simplicity, performance trade-off)**
- gRPC server runs in Python process via `simple_process` (uses Python's grpcio library)
- Effort: 1-2 days (gRPC integration only, no socket code)
- Benefits:
  - Fastest path to working gRPC (leverage Python's mature grpcio)
  - Minimal Eiffel socket code
  - Python handles all socket details
- Drawback:
  - Performance hit from subprocess overhead (not suitable for high throughput)
  - Eiffel loses control of socket layer
  - Message serialization happens in Python, not Eiffel
- Use case: If simplicity and fast delivery more critical than gRPC performance

**Action (REQUIRED BEFORE IMPLEMENTATION):**
Choose Option A (direct ISE NET), Option B (ecosystem-first), or Option C (maximum simplicity). This decision affects gRPC delivery timeline and architecture.

---

## Requirement Completeness - Challenged

### R-001: "Design by Contract on 100% of Public Interfaces"

**Requirement from research:** Every public class feature has preconditions, postconditions, invariants.

**Challenge:**
- Is 100% really necessary?
- What about simple getters (is_initialized)?
- What about one-liners?
- Does every test assert every contract?

**Verdict:** VALID
- DBC is Eiffel's core strength and manufacturing differentiator
- Contracts serve as API specification (Python can read require/ensure)
- 100% is achievable and worth the effort
- One-liners still benefit: is_initialized ensures non-Void state

**Action:**
- Keep 100% DBC as non-negotiable
- Skeleton contracts during Phase 1
- Strengthen with MML postconditions in Phase 5/6

---

### R-002: "≥100 Tests, ≥90% Coverage"

**Requirement from research:** Phase 1 success criterion is 100+ tests with 90% code coverage.

**Challenge:**
- Is 100 tests enough for three protocols?
- Is 90% coverage sufficient given manufacturing domain?
- What about adversarial testing?

**Evidence FOR:**
- 100 tests reasonable for MVP (core functionality)
- 90% coverage identifies untested edge cases
- Phase 5/6 adds stress/adversarial tests
- Simple libraries typically aim for 85-90%

**Verdict:** VALID
- Keep 100 tests and 90% coverage as Phase 1 target
- Plan for 150+ tests by Phase 6 (hardening)
- Coverage check will expose untested paths

**Action:**
- Keep requirements as stated
- Track coverage during implementation
- Flag any coverage <85% for Phase 4 review

---

### R-003: "Zero Compilation Warnings"

**Requirement from research:** ZERO POLICY - No warnings tolerated.

**Challenge:**
- Is this realistic given Eiffel ecosystem evolution?
- What about deprecation warnings from simple_* updates?
- Do we hold to ZERO or accept "benign" warnings?

**Verdict:** VALID
- ZERO is the right policy
- Warns about real problems in simple_* integrations
- Eiffel compiler is specific; warnings are actionable

**Action:**
- Strict ZERO policy
- Document any simple_* deprecations
- Plan simple_* version updates if needed

---

## Missing Requirements Identified

### MR-001: Message Ordering Guarantee

**Discovered Gap:** What order should requests be processed if Python sends them rapidly?

**Implication:**
- HTTP: Server might process out-of-order (load balanced servers)
- IPC: Single server maintains order
- gRPC: Unary requests processed in arrival order; streaming ordered per stream

**Action:** Add requirement: "Phase 1 assumes single Eiffel server per protocol. Multiple server coordination deferred to Phase 2."

---

### MR-002: Partial Message Handling

**Discovered Gap:** What happens if Python sends malformed partial message (e.g., incomplete JSON)?

**Implication:**
- HTTP: simple_web rejects malformed JSON (automatic)
- IPC: Message might arrive in two TCP packets; need length-prefix to detect completion
- gRPC: Protocol layer handles framing automatically

**Action:** Add requirement: "Phase 1 uses length-prefix framing (IPC) and protocol-level framing (HTTP/gRPC). Partial messages are re-requested by client."

---

### MR-003: Authentication/Authorization

**Discovered Gap:** Should simple_python authenticate Python clients?

**Implication:**
- HTTP: Could use API keys, OAuth, TLS
- IPC: Trust named pipe access control (Windows permissions)
- gRPC: Could use mTLS certificates

**Verdict:** OUT OF SCOPE Phase 1
- Phase 1: No authentication (development/testing only)
- Phase 2: Add authentication layer per protocol
- Note in documentation: "Not suitable for untrusted networks"

**Action:** Add Phase 2 requirement for authentication framework

---

### MR-004: Rate Limiting / Backpressure

**Discovered Gap:** What if Python floods Eiffel with validation requests faster than Eiffel can process?

**Implication:**
- HTTP: Connection timeout, 503 Service Unavailable
- IPC: Named pipe buffer fills, client blocks (natural backpressure)
- gRPC: Flow control via HTTP/2 window sizes

**Action:** Document Phase 1 behavior (no explicit rate limiting), plan Phase 2 queue management

---

### MR-005: Monitoring / Health Check

**Discovered Gap:** How does Python know if Eiffel server is healthy?

**Implication:**
- HTTP: Health endpoint GET /health returning 200 OK
- IPC: Send ping message, expect pong
- gRPC: Health checking proto built into gRPC

**Action:** Add Phase 2 requirement: "All protocols support health check endpoint"

---

## Assumptions About Eiffel Ecosystem - Challenged

### A-E001: "simple_* Ecosystem is Complete"

**Assumption:** simple_http, simple_web, simple_json, simple_ipc, simple_grpc are sufficient for simple_python.

**Challenge:**
- Are there gaps?
- Are these libraries truly production-ready?
- What about simple_logger (diagnostics)?

**Verdict:** MOSTLY VALID
- Core libraries are production (v1.0.0)
- simple_grpc is beta (acceptable risk)
- Socket I/O is genuinely missing (RISK-001)
- simple_logger optional but recommended

**Action:**
- Verify all library versions before implementation
- Plan simple_logger integration for diagnostics
- Document Socket I/O decision path

---

### A-E002: "SCOOP Concurrency Will Work Transparently"

**Assumption:** SCOOP-safe design (with `separate` keyword) will "just work" without explicit testing.

**Challenge:**
- Do we actually test SCOOP concurrency?
- Are there subtle race conditions in contract checks?
- Does message passing work correctly across separate processors?

**Verdict:** INVALID
- SCOOP requires explicit testing with concurrent calls
- Phase 6 hardening includes SCOOP stress tests
- Don't assume it works; verify it

**Action:**
- Add Phase 6 (hardening) requirement: "Concurrent validation stress test (100+ simultaneous requests)"
- Design test fixtures to exercise SCOOP processor isolation

---

### A-E003: "Eiffel MML Will Be Available"

**Assumption:** simple_mml library is available for model queries in postconditions.

**Challenge:**
- Does simple_mml exist?
- Is it production-ready?
- Are MML queries efficient enough?

**Verdict:** VALID but VERIFY
- Research showed simple_mml exists (v1.0.0+)
- MML queries add richness to contracts
- O(n) iteration cost is acceptable for Phase 1

**Action:**
- Verify simple_mml is available before Phase 4 (implementation)
- Plan optional MML model queries for collections (PYTHON_REQUEST.validation_rules, PYTHON_RESPONSE.errors)
- Document that MML strengthens contracts but not mandatory

---

## Assumptions About Python Integration - Challenged

### A-P001: "Python Developers Can Understand Eiffel Contracts"

**Assumption:** Python developers reading simple_python classes will understand preconditions, postconditions, invariants.

**Challenge:**
- Most Python developers don't know DBC
- Will they read Eiffel source or just use the library?
- Should we provide Contract documentation in Python?

**Verdict:** INCOMPLETE
- Keep contracts in Eiffel code (non-negotiable)
- But provide Python documentation that EXPLAINS contracts
- Phase 4 (API documentation) should document what each contract means

**Action:**
- Add Phase 4 requirement: "API documentation includes contract interpretation examples"
- Example: `PYTHON_REQUEST.is_valid` precondition becomes "Design data must not be empty"
- Create Python client library with docstrings explaining constraints

---

### A-P002: "Python Uses simple_http/simple_ipc for Clients"

**Assumption:** Python clients use simple_http or simple_ipc libraries (not standard http.client or socket).

**Challenge:**
- This is backwards! Python is the CLIENT, not the Eiffel side
- Python uses standard library (http.client, socket, grpcio)
- Eiffel uses simple_http/simple_web as SERVER

**Verdict:** MISUNDERSTOOD IN PLAN
- Simple_python (Eiffel) uses simple_http, simple_web, simple_ipc
- Python client scripts use standard http.client, socket, grpcio
- This is correct in research and implementation plan

**Action:**
- No action needed; already correct in design
- But clarify in documentation: "simple_* are Eiffel-side libraries; Python uses stdlib"

---

## Design Assumptions - Challenged

### A-D001: "Message IDs Should be UUIDs"

**Assumption:** PYTHON_MESSAGE.message_id is string in UUID format.

**Challenge:**
- UUID is 36 characters (overhead)
- Could use 64-bit integers instead
- Does Python client care about format?

**Evidence FOR:**
- UUIDs are globally unique (robust)
- Simple_* ecosystem likely has UUID generation
- Manufacturing audit trails benefit from UUIDs (traceability)

**Verdict:** VALID
- Keep UUID format for message_id
- Simple_base64 can encode UUIDs for IPC

**Action:**
- No change; UUID format is appropriate

---

### A-D002: "Timestamps in Microseconds"

**Assumption:** PYTHON_MESSAGE.timestamp is INTEGER_64 Unix timestamp in microseconds.

**Challenge:**
- Microseconds might be overkill (milliseconds sufficient?)
- 64-bit INTEGER might overflow in year 2262
- Is precision necessary for manufacturing?

**Verdict:** VALID
- Microseconds appropriate for real-time systems
- INTEGER_64 sufficient until year 2262 (long enough)
- Manufacturing validation may need precision

**Action:**
- Keep microseconds; document rationale in Phase 4

---

## Missing Design Decisions

### DD-001: Error Response Structure

**Decision Needed:** When Eiffel encounters error, what exactly goes in PYTHON_ERROR?

**Options:**
- Option A: Simple (error_code: INTEGER, error_message: STRING)
- Option B: Rich (error_code, message, context, stack_trace, suggestion)
- Option C: Minimal (error_code only, Python looks up message)

**Recommendation:** Option B for manufacturing (audit trail values), but keep stack_trace optional.

**Action:**
- Add to Step 4 (Class Design): Finalize PYTHON_ERROR structure with all fields

---

### DD-002: Validation Rules Extensibility

**Decision Needed:** How do customers define new validation rules?

**Options:**
- Option A: Hard-coded in Eiffel (customers submit code changes)
- Option B: Rules engine in Eiffel (load from configuration)
- Option C: Python submits rule definitions (dynamic, flexible)

**Recommendation:** Option A for Phase 1 (simplicity), Option B for Phase 2 (scalability).

**Action:**
- Phase 1 assumes hard-coded validators
- Document this limitation for Phase 2 extensibility

---

## Opportunities for Innovation

### I-001: Streaming Validation for Large Designs

**Opportunity:** Phase 2 feature - gRPC bi-directional streaming allows Python to send design in chunks while Eiffel validates incrementally, streaming errors back.

**Benefit:** Supports designs >10MB without full in-memory load

**Design Impact:** GRPC_PYTHON_BRIDGE.stream_validate(...) method with streaming response

**Action:** Plan for Phase 2; document in architecture

---

### I-002: Contract-to-OpenAPI Generation

**Opportunity:** Auto-generate OpenAPI spec from PYTHON_BRIDGE contracts for HTTP bridge.

**Benefit:** Python developers get auto-generated client stubs, documentation

**Design Impact:** Code generator (maybe simple_spec_gen?) reads Eiffel contracts, emits OpenAPI

**Action:** Plan for Phase 2; requires simple_spec_gen or similar

---

### I-003: Manufacturing Compliance Report Generation

**Opportunity:** Phase 2 - Generate IEC 61131 compliance report from audit trail.

**Benefit:** Manufacturing customers get audit evidence with one click

**Design Impact:** COMPLIANCE_REPORT_GENERATOR class aggregates MANUFACTURING_METADATA

**Action:** Plan for Phase 2 compliance framework

---

## Conclusion

**Assessment:** Research phase was thorough; assumptions are largely VALID with noted caveats.

**Critical Adjustments Required:**
1. Verify Socket I/O options before gRPC implementation
2. Verify simple_ipc Unix domain socket support
3. Design PYTHON_ERROR structure (Step 4)
4. Design validation rules extensibility (Phase 2)

**Opportunities for Consideration:**
- Streaming validation (Phase 2)
- OpenAPI generation (Phase 2)
- Compliance report generation (Phase 2)

**Recommendation:** Proceed to Step 4 (CLASS-DESIGN) with above clarifications noted.

---

End of CHALLENGED-ASSUMPTIONS.md
