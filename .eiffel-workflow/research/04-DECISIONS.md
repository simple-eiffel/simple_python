# DECISIONS: simple_python Eiffel-Python Bridge Library

**Date:** January 28, 2026
**Research Phase:** Step 4 - Make Choices

---

## Decision Log

### D-001: Multi-Target Architecture (HTTP + IPC + gRPC)

**Question:** Should we build one unified bridge or three independent protocol targets?

**Options:**

1. **Single Protocol (HTTP Only)**
   - Pros: Simpler, fewer test variants, easier to maintain
   - Cons: Not suitable for all manufacturing use cases; loses IPC performance for same-machine; no streaming RPC

2. **Two Protocols (HTTP + IPC)**
   - Pros: Covers 80% of use cases; manageable complexity
   - Cons: Doesn't support cloud-native streaming; gRPC becoming standard in manufacturing

3. **Three Protocols (HTTP + IPC + gRPC)** ✅ **CHOSEN**
   - Pros: Flexible deployment; customers pick target matching their environment; shared core prevents code duplication
   - Cons: Three test variants; gRPC needs socket I/O

**Decision:** Three protocols via ECF multi-target architecture

**Rationale:**
- Manufacturing customers deploy to different environments (local, cloud, hybrid)
- HTTP: Industry standard REST (80% of integrations), cloud-ready
- IPC: High-performance same-machine validation, embedded systems
- gRPC: Type-safe RPC, streaming, future-proof, cloud-native
- ECF targets allow shared core classes, independent compilation

**Implications:**
- Must design shared PYTHON_BRIDGE interface
- Each target has own test fixtures (setup/teardown per protocol)
- Deferred: Resolve gRPC socket I/O requirement (Phase 1 or Phase 2)

**Reversible:** YES (can defer gRPC to Phase 2 if needed)

---

### D-002: Shared Message Interface vs Protocol-Specific Messages

**Question:** Should messages be abstract (shared interface) or protocol-specific?

**Options:**

1. **Protocol-Specific Messages**
   - HTTP uses simple JSON messages
   - IPC uses custom binary framing
   - gRPC uses Protocol Buffers
   - Pros: Optimized for each protocol
   - Cons: Duplicated logic, harder to change message schema

2. **Shared Interface + Protocol Adapters** ✅ **CHOSEN**
   - Deferred PYTHON_MESSAGE interface
   - Each protocol inherits and implements serialization
   - Cons: Slight overhead
   - Pros: Shared validation contracts, easier to maintain

**Decision:** Shared PYTHON_MESSAGE interface with protocol-specific serialization

**Rationale:**
- Message validation contracts (preconditions) apply universally
- Bug fixes in message handling fix all three protocols
- Design by Contract requires contracts on public interfaces (forces shared semantics)
- Slight serialization overhead negligible vs. network latency

**Implications:**
- Core message types (PYTHON_REQUEST, PYTHON_RESPONSE) deferred
- Each protocol: class HTTP_VALIDATION_REQUEST inherits PYTHON_REQUEST
- Serialization methods (to_bytes, from_bytes) are protocol-specific

**Reversible:** YES (can refactor to protocol-specific if performance critical)

---

### D-003: Validation Logic Placement (Eiffel vs Python)

**Question:** Should validation logic be in Eiffel or Python?

**Options:**

1. **Eiffel Validation Only**
   - Pros: High assurance (DBC contracts), type safety, void-safe
   - Cons: Python ecosystem features unavailable, no machine learning
   - Cons: Control board validation is Eiffel domain anyway

2. **Python Validation Only**
   - Pros: Rich ecosystem, machine learning ready, fast iteration
   - Cons: No Design by Contract, null pointer risks, type uncertainty

3. **Hybrid: Core in Eiffel, Extensions in Python** ✅ **CHOSEN**
   - Eiffel: High-assurance validation logic (electrical, firmware, safety checks)
   - Python: Orchestration, visualization, analysis, hardware control
   - Both via bridge: Communication over HTTP/IPC/gRPC

**Decision:** Eiffel owns validation logic; Python owns orchestration

**Rationale:**
- Eiffel excels at verifying complex contracts (control board design rules)
- Manufacturing validation requires high assurance (DBC, type safety)
- Python valuable for visualization, analysis, system integration
- Separation of concerns: Eiffel validates, Python coordinates

**Implications:**
- simple_python is transport layer, not validation logic
- Customers bring their Eiffel validation classes
- Python scripts call validation via bridge

**Reversible:** YES (could shift validation to Python if needed, but not recommended)

---

### D-004: Serialization Format (JSON vs Protocol Buffers vs MessagePack)

**Question:** What serialization format for HTTP and gRPC?

**Options:**

1. **JSON for All**
   - Pros: Simple, human-readable, works everywhere
   - Cons: No schema enforcement, larger messages, type ambiguity

2. **Protocol Buffers for All**
   - Pros: Efficient, schema-driven, type-safe, standard for gRPC
   - Cons: Requires .proto file setup, binary format

3. **JSON (HTTP) + Protocol Buffers (gRPC)** ✅ **CHOSEN**
   - HTTP: JSON (simple, REST convention, simple_json validates schemas)
   - gRPC: Protocol Buffers (type-safe, efficient, gRPC native)
   - IPC: Custom binary framing (length-prefix + payload)

**Decision:** Protocol-specific optimal format (JSON for HTTP, Protobuf for gRPC)

**Rationale:**
- JSON is REST convention; Python developers expect JSON
- Protocol Buffers standard for gRPC; schema-driven design
- simple_json provides JSON Schema validation (Eiffel-unique advantage)
- Each format optimized for its transport layer

**Implications:**
- HTTP_VALIDATION_REQUEST: to_json() / from_json()
- GRPC_VALIDATION_REQUEST: to_protobuf() / from_protobuf()
- IPC_VALIDATION_MESSAGE: to_bytes() / from_bytes()

**Reversible:** PARTIALLY (could standardize on Protocol Buffers, but loses JSON simplicity)

---

### D-005: Socket I/O for gRPC (Build vs Wrap vs Defer)

**Question:** How to handle TCP sockets needed for gRPC?

**Options:**

1. **Build simple_socket Library**
   - Effort: 1-2 weeks new library
   - Pro: General-purpose, reusable, SCOOP-compatible
   - Con: Blocks gRPC phase, new project overhead
   - Risk: Socket I/O is complex, concurrency bugs possible

2. **Wrap ISE Socket Library**
   - Effort: Few days
   - Pro: Leverages existing code
   - Con: Violates simple_* first policy, ISE licensing
   - Risk: ISE sockets not SCOOP-compatible?

3. **Use simple_process Delegation**
   - Effort: 1 day (Python subprocess handles socket I/O)
   - Pro: No new library, pure Python handles sockets
   - Con: gRPC performance reduced, process overhead
   - Risk: Latency (subprocess spawning)

4. **Defer gRPC to Phase 2** ✅ **CHOSEN (for MVP)**
   - HTTP + IPC in Phase 1 (fully supported)
   - gRPC + socket decision in Phase 2 (with clearer scope)

**Decision:** Defer gRPC implementation and socket I/O decision to Phase 2

**Rationale:**
- HTTP + IPC sufficient for MVP and cover 80% of use cases
- Socket I/O decision requires more research (can defer)
- Unblocks Phase 1 completion in 4-5 days
- Phase 2 can evaluate socket_options with customer feedback

**Implications:**
- Phase 1: HTTP_BRIDGE + IPC_BRIDGE targets only
- Phase 2: Resolve socket I/O, implement GRPC_BRIDGE
- All three ready for production release (Phase 2)

**Reversible:** YES (can add gRPC in Phase 2 regardless of socket approach)

---

### D-006: Testing Strategy (Protocol Isolation)

**Question:** How to test all three protocols without cross-contamination?

**Options:**

1. **Single Test Suite, All Protocols**
   - Run same tests against HTTP, IPC, gRPC servers
   - Pro: Single test code, comprehensive coverage
   - Con: Tests must be protocol-agnostic (difficult)

2. **Separate Test Fixtures Per Protocol** ✅ **CHOSEN**
   - TEST_HTTP_BRIDGE: HTTP-specific setup, validation
   - TEST_IPC_BRIDGE: Named pipe setup, validation
   - TEST_GRPC_BRIDGE: gRPC server setup, validation
   - Shared test scenarios (validation request/response)
   - Pro: Each fixture optimized for its protocol
   - Con: Test code duplication (acceptable)

**Decision:** Separate test fixtures per protocol, shared scenarios

**Rationale:**
- Each protocol needs different setup (HTTP mock server, named pipe, gRPC frame)
- Setup/teardown differs significantly (port allocation, pipe creation, cleanup)
- Tests verify protocol-specific behavior (HTTP status codes, IPC message framing)
- Shared scenarios ensure semantic consistency

**Implications:**
- test/test_http_bridge.e - HTTP-specific tests
- test/test_ipc_bridge.e - IPC-specific tests
- test/test_grpc_bridge.e - gRPC-specific tests (Phase 2)
- test/test_python_message.e - Shared message contract tests

**Reversible:** YES (could refactor to single test suite if code duplication becomes issue)

---

### D-007: SCOOP Concurrency Model

**Question:** How to handle concurrent validation requests (SCOOP)?

**Options:**

1. **No Concurrency (Sequential)**
   - Single thread, one validation at a time
   - Pro: Simple, no race conditions
   - Con: Doesn't leverage SCOOP, manufacturing systems may have concurrent validators

2. **SCOOP with separate Keyword** ✅ **CHOSEN**
   - Separate PYTHON_BRIDGE for each concurrent client
   - SCOOP processor per bridge instance
   - No explicit synchronization needed (SCOOP guarantees race-freedom)

**Decision:** Use SCOOP for safe concurrent validation

**Rationale:**
- Manufacturing validation often concurrent (multiple test runs simultaneously)
- SCOOP provides race-free concurrency without locks
- Eiffel strength: concurrent systems that work
- Python clients can make parallel validation calls

**Implications:**
- Each connection: separate PYTHON_BRIDGE instance
- No shared state between bridges (each validates independently)
- SCOOP processor ensures thread-safe message handling
- Capacity scaling: One Eiffel process = multiple SCOOP processors

**Reversible:** YES (can simplify to sequential if SCOOP causes issues)

---

### D-008: Documentation and Python Client Library

**Question:** Should we provide Python client library or just document protocol?

**Options:**

1. **Protocol Documentation Only**
   - Pros: Simple, minimal Python code
   - Cons: Developers must implement HTTP/IPC clients themselves

2. **Thin Python Client Library** ✅ **CHOSEN**
   - `simple_python.http` - HTTP client (wraps requests)
   - `simple_python.ipc` - IPC client (wraps pywin32)
   - Simple API: `validate(design_data) -> ValidationResult`

**Decision:** Provide thin Python client library for ease of use

**Rationale:**
- Eighty-ninety rule: 80-90% of developers just want to call validate()
- Client library hides protocol details
- Easier for Python developers (native library, not Eiffel)
- Adoption increases if barrier to entry low

**Implications:**
- Create simple_python Python package (PyPI)
- Include HTTP and IPC client classes
- Simple facade: `from simple_python import validate`
- Documentation with examples

**Reversible:** YES (can drop Python library if not adopted)

---

## Decision Summary Table

| Decision | Choice | Confidence | Reversible |
|----------|--------|-----------|-----------|
| D-001: Multi-target | HTTP + IPC + gRPC (3 targets) | HIGH | YES |
| D-002: Message Interface | Shared PYTHON_MESSAGE interface | HIGH | YES |
| D-003: Validation Logic | Eiffel core, Python orchestration | HIGH | YES |
| D-004: Serialization | JSON (HTTP), Protobuf (gRPC), Binary (IPC) | HIGH | PARTIAL |
| D-005: Socket I/O | Defer gRPC to Phase 2 | HIGH | YES |
| D-006: Testing | Per-protocol fixtures, shared scenarios | MEDIUM | YES |
| D-007: Concurrency | SCOOP separate keyword | MEDIUM | YES |
| D-008: Python Library | Thin client library (PyPI) | HIGH | YES |

---

## Next Steps

Proceed to Step 5: INNOVATIONS - Identify novel approaches that differentiate simple_python.
