# simple_python: Eiffel-Python Bridge Library

**Research & Planning Document**

**Date:** January 28, 2026
**Status:** Research Phase - Ready for /eiffel-research skill
**Target:** Industrial manufacturer validation systems

---

## Executive Summary

Build **simple_python**: A unified Eiffel library providing three independent protocol bridges to Python systems. Single codebase with three deployment targets (HTTP, IPC, gRPC) sharing common message contracts and core classes.

**Intended Use Case:** Validate/verify electronic designs for industrial control boards and embedded code. Python handles orchestration, data analysis, visualization, or hardware control. Eiffel provides authoritative validation with Design by Contract.

**Architecture:** ECF multi-target design with shared bridge interface, common message types, and three protocol implementations as independent targets.

---

## Problem Statement

### Context
Industrial manufacturer producing plant-level chillers/cooling/AC systems needs to:
1. **Validate control board electronic designs** (Eiffel domain: high-assurance, contracts, type safety)
2. **Integrate with Python** for orchestration, analysis, visualization, or hardware control
3. **Deploy flexibly** to different customer environments with different integration needs

### Current State
- Eiffel ecosystem has **mature communication libraries**: simple_http, simple_ipc, simple_websocket, simple_grpc, simple_mq, simple_json
- No unified "Python bridge" library exists
- Each protocol requires independent integration if approached separately

### Why Not Single Protocol?
- **Customer A** might need HTTP REST API (cloud integration)
- **Customer B** might need IPC (same-machine, low-latency, highest reliability)
- **Customer C** might need gRPC (type-safe RPC with streaming)
- Forcing all into one protocol limits market/deployment flexibility

---

## Proposed Solution: Three-Target Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│         simple_python.ecf (Single Eiffel Codebase)          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Core Shared Classes (Bridge Interface + Messages)          │
│  ────────────────────────────────────────────────────       │
│  • PYTHON_BRIDGE (deferred interface)                       │
│  • PYTHON_MESSAGE (common message contract)                 │
│  • PYTHON_REQUEST, PYTHON_RESPONSE (semantics)              │
│  • PYTHON_ERROR (error contract)                            │
│  • Message serialization/deserialization                    │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  HTTP Bridge Implementation              Target: http_bridge│
│  ─────────────────────────────────────────────────────────  │
│  • HTTP_PYTHON_BRIDGE extends PYTHON_BRIDGE                 │
│  • Uses simple_http for client calls                        │
│  • Uses simple_web for server hosting                       │
│  • JSON serialization via simple_json                       │
│  • Endpoint routing, authentication, retries                │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  IPC Bridge Implementation               Target: ipc_bridge │
│  ─────────────────────────────────────────────────────────  │
│  • IPC_PYTHON_BRIDGE extends PYTHON_BRIDGE                  │
│  • Uses simple_ipc for named pipes (Windows)                │
│  • Message framing: length-prefix + payload                 │
│  • Bidirectional byte/string streaming                      │
│  • Reliable message delivery with acks                      │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  gRPC Bridge Implementation              Target: grpc_bridge│
│  ─────────────────────────────────────────────────────────  │
│  • GRPC_PYTHON_BRIDGE extends PYTHON_BRIDGE                 │
│  • Uses simple_grpc (protocol layer)                        │
│  • Socket I/O integration (new requirement)                 │
│  • Protocol Buffers message encoding                        │
│  • HTTP/2 frame handling                                    │
│  • Streaming RPC support (4 types)                          │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Test Suite                              Target: tests      │
│  ─────────────────────────────────────────────────────────  │
│  • Unit tests for message contracts                         │
│  • HTTP bridge tests (with mock server)                     │
│  • IPC bridge tests (with named pipe simulation)            │
│  • gRPC bridge tests (with frame mocking)                   │
│  • Python integration tests (spawn Python scripts)          │
│  • Setup/teardown per protocol variant                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Why This Architecture Works

**1. Single Codebase**
- All protocol implementations share same bridge interface contracts
- Bugs in message validation fixed once, inherited by all three
- Code review focuses on core semantics, not protocol details

**2. Independent Deployment**
- Customer A deploys `http_bridge` executable
- Customer B deploys `ipc_bridge` executable
- Customer C deploys `grpc_bridge` executable
- Same validation logic, different transport layers

**3. Unified Testing**
- Single test suite validates all three protocol variants
- Each protocol has isolated test fixtures (setup/teardown)
- Test failures immediately catch protocol-specific bugs
- No "dead code" - all targets must compile and pass tests

**4. ECF Multi-Target Leverage**
- ECF targets are designed exactly for this pattern
- Shared classes via common root
- Protocol-specific classes in separate clusters
- Seamless reuse without duplication

---

## Three Bridge Implementations

### Bridge 1: HTTP REST API (simple_http + simple_json)

**Dependencies:**
- simple_http (client) - mature, v1.0.0
- simple_web (server) - mature, v1.0.0
- simple_json (serialization) - production, v1.0.0, 100% test coverage

**What It Does:**
```
Python                              Eiffel
  ├─ HTTP GET /api/validate         │
  │  (with query params)             │
  └─────────────────────────────────→ HTTP_PYTHON_BRIDGE
                                     ├─ Parse request
                                     ├─ Call Eiffel validator
                                     └─ Serialize response as JSON
  ├─ HTTP 200 + JSON response       ←──────────────────────────
  │  {"status": "valid", "errors": []}
```

**Strengths:**
- Most mature, production-hardened
- Language-agnostic (any HTTP client works)
- Cloud-ready (can be deployed behind load balancer)
- JSON Schema validation ensures type safety
- Resilience patterns built-in (retry, circuit breaker, timeout)

**Limitations:**
- Network latency (even localhost)
- JSON serialization overhead
- Not suited for ultra-high-frequency calls

**Use Cases:**
- Cloud integration
- Distributed validation nodes
- Web UI backend
- Heterogeneous system integration

---

### Bridge 2: Named Pipes IPC (simple_ipc)

**Dependencies:**
- simple_ipc (bidirectional IPC) - production, v2.0.0
- Message framing protocol (custom, simple)

**What It Does:**
```
Python (named pipe client)          Eiffel (named pipe server)
  ├─ Connect to \\.\pipe\validator  │
  │  (Windows)                       │
  ├─ Write: [4-byte length][payload]│
  └─────────────────────────────────→ IPC_PYTHON_BRIDGE
                                     ├─ Read message
                                     ├─ Call Eiffel validator
                                     └─ Write: [4-byte length][result]
  ├─ Read response                  ←──────────────────────────
  │  [4-byte length][result bytes]
```

**Strengths:**
- Zero network overhead (same machine)
- Ultra-low latency
- Bidirectional streaming
- Direct byte/string exchange
- Simple protocol (length-prefix framing)

**Limitations:**
- Windows-only (named pipes)
- Same machine only
- Must handle message framing manually
- No built-in encryption

**Use Cases:**
- Local validation (device under test on same machine)
- Real-time measurement capture
- High-frequency bidirectional communication
- Tightly coupled systems

---

### Bridge 3: gRPC RPC (simple_grpc + Socket I/O)

**Dependencies:**
- simple_grpc (protocol layer) - beta, provides Protocol Buffers + HTTP/2 framing
- **Socket I/O library (NEW REQUIREMENT)** - must implement TCP sockets for Eiffel
- simple_base64 (for Protocol Buffers encoding)

**What It Does:**
```
Python gRPC client                  Eiffel gRPC server
  ├─ gRPC call: Validate(request)   │
  │  (with protobuf encoding)        │
  └─────────────────────────────────→ GRPC_PYTHON_BRIDGE
     (HTTP/2 frames)                 ├─ Decode protobuf
                                     ├─ Call Eiffel validator
                                     ├─ Encode protobuf response
                                     └─ Send HTTP/2 frame
  ├─ gRPC response: ValidateReply   ←──────────────────────────
  │  (protobuf encoded)
```

**Strengths:**
- Type-safe RPC (Protocol Buffers contracts)
- Streaming support (unary, server-streaming, client-streaming, bidirectional)
- Works remotely (cloud-ready)
- Modern protocol (HTTP/2)
- Standard: Python has native gRPC support

**Limitations:**
- Requires socket I/O integration (NEW work)
- More complex protocol layer
- Still in beta relative to HTTP/IPC
- Protocol Buffers schema generation step

**Use Cases:**
- Distributed validation across network
- Type-safe service calls
- Real-time streaming (e.g., continuous measurement capture with callbacks)
- Cloud deployment
- Microservice architecture

---

## Shared Core Classes (Bridge Interface)

### PYTHON_BRIDGE (Deferred Interface)

```eiffel
deferred class PYTHON_BRIDGE

feature -- Initialization

    initialize
            -- Set up bridge (server listening, client connection, etc.)
        deferred
        end

feature -- Communication

    send_message (a_request: PYTHON_REQUEST)
            -- Send request to Python endpoint.
        require
            bridge_initialized: is_initialized
            request_valid: a_request /= Void
        deferred
        ensure
            message_sent: last_message_sent_timestamp > old last_message_sent_timestamp
        end

    receive_response: PYTHON_RESPONSE
            -- Receive response from Python.
        require
            bridge_initialized: is_initialized
        deferred
        ensure
            response_valid: Result /= Void
            has_data: Result.has_data
        end

feature -- Status

    is_initialized: BOOLEAN
            -- Is bridge ready for communication?
        deferred
        end

    is_connected: BOOLEAN
            -- Is connection active?
        deferred
        end

    last_error: detachable STRING_32
            -- Last error message (Void if no error).
        deferred
        end

feature -- Cleanup

    shutdown
            -- Close bridge, release resources.
        deferred
        ensure
            not_connected: not is_connected
        end

end
```

### PYTHON_MESSAGE (Common Message Contract)

```eiffel
deferred class PYTHON_MESSAGE

feature -- Access

    message_id: STRING_32
            -- Unique message identifier.
        deferred
        end

    message_type: STRING_32
            -- Type of message (e.g., "validate_request", "error_response").
        deferred
        end

    payload: detachable PYTHON_PAYLOAD
            -- Message payload (deferred subclasses define type).
        deferred
        end

    timestamp: INTEGER_64
            -- Unix timestamp (microseconds).
        deferred
        end

feature -- Serialization

    to_bytes: ARRAY [NATURAL_8]
            -- Serialize message to bytes (protocol-specific).
        deferred
        end

    from_bytes (a_bytes: ARRAY [NATURAL_8])
            -- Deserialize message from bytes.
        require
            bytes_valid: a_bytes /= Void and then a_bytes.count > 0
        deferred
        ensure
            message_deserialized: message_id /= Void
        end

feature -- Validation

    is_valid: BOOLEAN
            -- Is message well-formed?
        deferred
        ensure
            has_id: Result implies (message_id /= Void)
            has_type: Result implies (message_type /= Void)
        end

end
```

### PYTHON_REQUEST / PYTHON_RESPONSE (Semantics)

```eiffel
class PYTHON_VALIDATION_REQUEST
    inherit PYTHON_MESSAGE
        -- Request: validate design/code

feature -- Access

    design_data: STRING_32
            -- Design or code to validate.
        attribute
        end

    validation_rules: ARRAY [STRING_32]
            -- Rules to apply (optional).
        attribute
        end

feature -- Implementation

    to_bytes: ARRAY [NATURAL_8]
        do
            -- Protocol-specific serialization (HTTP JSON, IPC bytes, gRPC protobuf)
        end

end

class PYTHON_VALIDATION_RESPONSE
    inherit PYTHON_MESSAGE
        -- Response: validation results

feature -- Access

    is_valid: BOOLEAN
            -- Did validation pass?
        attribute
        end

    errors: ARRAY [STRING_32]
            -- List of errors found (empty if valid).
        attribute
        end

    warnings: ARRAY [STRING_32]
            -- Non-fatal issues (empty if none).
        attribute
        end

feature -- Implementation

    to_bytes: ARRAY [NATURAL_8]
        do
            -- Protocol-specific serialization
        end

end
```

**Key Properties:**
- Each message type has deferred interface
- Serialization/deserialization is protocol-specific (HTTP JSON vs. IPC bytes vs. gRPC protobuf)
- Validation contracts ensure data integrity regardless of transport

---

## Development Roadmap

### Phase 1: Core Interfaces & Message Types
**Estimated:** 0.5 day (2000 LOC)

Deliverables:
- PYTHON_BRIDGE deferred interface
- PYTHON_MESSAGE base class
- PYTHON_REQUEST, PYTHON_RESPONSE (and variants)
- PYTHON_ERROR error handling
- Shared utilities (message ID generation, timestamps, etc.)

Output: Contracts defining what ALL three bridges must implement.

---

### Phase 2: HTTP Bridge Implementation
**Estimated:** 1 day (4000-4500 LOC)

Deliverables:
- HTTP_PYTHON_BRIDGE (implements PYTHON_BRIDGE)
- HTTP message serialization (PYTHON_MESSAGE → JSON)
- REST endpoint routing (GET /api/validate, POST /api/analyze, etc.)
- Request/response handlers
- Error mapping (Eiffel errors → HTTP status codes)
- Authentication/authorization support

Output: Executable HTTP server + client for Python integration.

Dependencies:
- simple_http (client)
- simple_web (server)
- simple_json (serialization)

---

### Phase 3: IPC Bridge Implementation
**Estimated:** 1 day (4000-4500 LOC)

Deliverables:
- IPC_PYTHON_BRIDGE (implements PYTHON_BRIDGE)
- Named pipe connection management (Windows)
- Message framing protocol (4-byte length prefix + payload)
- Bidirectional message streaming
- Reliable delivery with acknowledgments
- Error recovery (reconnect on broken pipe)

Output: Executable IPC server accepting Python named pipe clients.

Dependencies:
- simple_ipc (named pipes)

---

### Phase 4: gRPC Bridge Implementation
**Estimated:** 1-2 days (5000-6000 LOC)

Deliverables:
- GRPC_PYTHON_BRIDGE (implements PYTHON_BRIDGE)
- Protocol Buffers message encoding (build on simple_grpc)
- Socket I/O layer (NEW - TCP sockets for Eiffel)
- HTTP/2 frame handling
- gRPC service registration
- 4 streaming method types (unary, server-stream, client-stream, bidi)
- gRPC status/error handling

Output: Executable gRPC server callable by Python gRPC clients.

Dependencies:
- simple_grpc (protocol layer)
- **Socket I/O library (to be created or sourced)**

**Critical Blocker:** Socket I/O implementation. simple_grpc provides protocol layer but not socket I/O. Must either:
1. Create new socket I/O library (Windows WinSock wrapper)
2. Wrap existing ISE socket functionality
3. Use simple_process to delegate to Python subprocess for this variant

---

### Phase 5: Test Suite
**Estimated:** 1 day (4000-4500 LOC)

Deliverables:
- Unit tests (message contracts, serialization/deserialization)
- HTTP bridge tests (mock HTTP server, request/response round-trip)
- IPC bridge tests (named pipe simulation, message framing)
- gRPC bridge tests (frame mocking, protobuf encoding)
- Integration tests (spawn Python scripts, validate bidirectional communication)
- Setup/teardown per protocol variant
- Error scenario testing

Output: Comprehensive test suite validable by `/eiffel-verify`.

---

**Total Estimate:** 4-5 days, 17,000-20,000 LOC
- Phase 1 (Core): 0.5 day
- Phase 2 (HTTP): 1 day
- Phase 3 (IPC): 1 day
- Phase 4 (gRPC): 1-2 days
- Phase 5 (Tests): 1 day

**With 4000-4500 LOC/day capability: Achievable in focused sprint.**

---

## ECF Structure

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system name="simple_python" uuid="[generate-new-uuid]">

    <!-- Core Target: Library for reuse -->
    <target name="simple_python" library="true">
        <root class="SIMPLE_PYTHON" feature="default_create"/>
        <capability>
            <concurrency support="scoop"/>
            <void_safety support="all"/>
        </capability>
        <cluster name="src" location="src\"/>
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="simple_http" location="$SIMPLE_EIFFEL/simple_http/simple_http.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_ipc" location="$SIMPLE_EIFFEL/simple_ipc/simple_ipc.ecf"/>
        <library name="simple_grpc" location="$SIMPLE_EIFFEL/simple_grpc/simple_grpc.ecf"/>
    </target>

    <!-- HTTP Bridge Target -->
    <target name="http_bridge" extends="simple_python">
        <root class="HTTP_PYTHON_BRIDGE_SERVER" feature="make"/>
        <cluster name="http" location="src/http\"/>
    </target>

    <!-- IPC Bridge Target -->
    <target name="ipc_bridge" extends="simple_python">
        <root class="IPC_PYTHON_BRIDGE_SERVER" feature="make"/>
        <cluster name="ipc" location="src/ipc\"/>
    </target>

    <!-- gRPC Bridge Target -->
    <target name="grpc_bridge" extends="simple_python">
        <root class="GRPC_PYTHON_BRIDGE_SERVER" feature="make"/>
        <cluster name="grpc" location="src/grpc\"/>
    </target>

    <!-- Test Target: Validates all three -->
    <target name="simple_python_tests" extends="simple_python">
        <root class="TEST_APP" feature="make"/>
        <library name="testing" location="$ISE_LIBRARY/library/testing/testing.ecf"/>
        <cluster name="tests" location="test\"/>
    </target>

</system>
```

---

## Dependencies & External Requirements

### Eiffel Libraries (Available)
- ✅ simple_http (v1.0.0) - REST API client
- ✅ simple_web (v1.0.0) - HTTP server
- ✅ simple_json (v1.0.0) - JSON serialization + Schema validation
- ✅ simple_ipc (v2.0.0) - Named pipes IPC
- ✅ simple_grpc (beta) - gRPC protocol layer
- ✅ simple_base64 - Base64 encoding (for protobuf)
- ✅ base (ISE) - Standard library
- ✅ testing (ISE) - EQA_TEST_SET

### New Requirement
- ⚠️ **Socket I/O Library** - Not yet available
  - Needed for gRPC bridge to actually send/receive over TCP
  - Options:
    1. Create new `simple_socket` library (WinSock wrapper)
    2. Wrap ISE's built-in socket classes
    3. Use `simple_process` to delegate gRPC encoding to Python subprocess

### External (Python Side)
- Python 3.8+
- http.client (stdlib) - for HTTP bridge
- socket (stdlib) - for IPC bridge (pywin32 for named pipes on Windows)
- grpcio + grpcio-tools - for gRPC bridge

---

## Success Criteria

### Phase 1: Core (Complete)
- [ ] PYTHON_BRIDGE interface defined
- [ ] Message classes with serialization contracts
- [ ] Error handling deferred interface
- [ ] Compiles zero warnings

### Phase 2: HTTP (Complete)
- [ ] HTTP_PYTHON_BRIDGE implements PYTHON_BRIDGE
- [ ] HTTP tests pass (100%)
- [ ] Python script can call Eiffel validation via HTTP
- [ ] JSON Schema validation on requests/responses
- [ ] Resilience patterns (retry, timeout, error handling)

### Phase 3: IPC (Complete)
- [ ] IPC_PYTHON_BRIDGE implements PYTHON_BRIDGE
- [ ] IPC tests pass (100%)
- [ ] Python script can send/receive via named pipes
- [ ] Message framing protocol robust
- [ ] Bidirectional streaming verified

### Phase 4: gRPC (Complete)
- [ ] GRPC_PYTHON_BRIDGE implements PYTHON_BRIDGE
- [ ] Socket I/O integration resolved
- [ ] gRPC tests pass (100%)
- [ ] Python gRPC client can call Eiffel services
- [ ] Protocol Buffers encoding validated
- [ ] All 4 streaming types work

### Phase 5: Tests (Complete)
- [ ] All bridges: 100% test pass rate
- [ ] Unit tests: Message contracts
- [ ] Integration tests: Python ↔ Eiffel round-trip
- [ ] Setup/teardown: Per-protocol isolation
- [ ] No compilation warnings

### Deployment
- [ ] http_bridge executable deployable
- [ ] ipc_bridge executable deployable
- [ ] grpc_bridge executable deployable
- [ ] All three documented with usage examples
- [ ] Production-grade error handling

---

## Risk Assessment

### Low Risk
- HTTP implementation (simple_http/simple_json mature)
- IPC implementation (simple_ipc proven)
- Message contracts (standard Eiffel DBC)
- Testing infrastructure (standard EQA patterns)

### Medium Risk
- gRPC protocol implementation (simple_grpc is beta)
- Socket I/O integration (doesn't exist yet - blocking item)
- Multi-target ECF configuration (straightforward but needs validation)

### High Risk
- **Socket I/O library missing** - This is the critical blocker for gRPC
  - Decision required: Build vs. adapt existing vs. delegate to subprocess
  - Could delay gRPC phase 1-2 weeks if new library needed
  - Could be bypassed if using simple_process delegation (less ideal)

### Mitigation
- Build HTTP + IPC first (independent)
- Resolve socket I/O approach before starting Phase 4
- gRPC as optional stretch goal if socket I/O not available

---

## Python Integration Examples

### HTTP Bridge Usage (Python Side)
```python
import requests
import json

# Call Eiffel validator via HTTP
response = requests.post(
    'http://localhost:8080/api/validate',
    json={'design_data': board_schematic, 'rules': ['rule1', 'rule2']},
    timeout=5
)

if response.status_code == 200:
    result = response.json()
    print(f"Valid: {result['is_valid']}")
    if result['errors']:
        print(f"Errors: {result['errors']}")
```

### IPC Bridge Usage (Python Side)
```python
import socket
import struct

# Connect to Eiffel via named pipe
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(r'\\.\pipe\eiffel_validator')

# Send: [4-byte length][payload]
message = b'{"design": "..."}'
sock.sendall(struct.pack('I', len(message)) + message)

# Receive: [4-byte length][response]
length_bytes = sock.recv(4)
length = struct.unpack('I', length_bytes)[0]
response = sock.recv(length)
```

### gRPC Bridge Usage (Python Side)
```python
import grpc
from python_pb2_grpc import EiffelValidatorStub
from python_pb2 import ValidateRequest

# Call Eiffel gRPC service
channel = grpc.insecure_channel('localhost:50051')
stub = EiffelValidatorStub(channel)

request = ValidateRequest(design_data=board_schematic, rules=['rule1'])
response = stub.Validate(request)

print(f"Valid: {response.is_valid}")
print(f"Errors: {response.errors}")
```

---

## Next Steps

### Immediate (Before Code)
1. Confirm socket I/O approach for gRPC (build new library? wrap ISE? delegate?)
2. Validate ECF multi-target structure
3. Design message schema (what exactly does Python need to send/receive?)
4. Determine whether all three targets deploy, or HTTP+IPC as MVP

### Then: /eiffel-research Skill
Run `/eiffel.research d:\prod\simple_python` to:
- Validate research assumptions
- Refine architecture based on ecosystem patterns
- Identify any library gaps or conflicts

### Then: /eiffel-spec Skill
Transform research into formal specification with:
- Class hierarchies
- Message type definitions
- Protocol layer specifications
- Test coverage requirements

### Then: /eiffel-contracts through /eiffel-ship
Build Phase 1-7 using standard eiffel-* workflow.

---

## Questions for Clarification

Before proceeding to /eiffel-research, resolve:

1. **Socket I/O for gRPC:** What's the approach?
   - Build new simple_socket library?
   - Wrap ISE socket classes?
   - Use simple_process delegation?

2. **Python Side Scope:** Who owns Python code?
   - Simple example scripts (your responsibility)?
   - Full client libraries (customer responsibility)?
   - Test harness (built into simple_python tests)?

3. **Deployment:** Are all three targets required in v1.0.0?
   - Or HTTP+IPC as MVP, gRPC as Phase 2?

4. **Message Schema:** What exactly validates/verifies?
   - Electronic design format (input)?
   - Validation rules (input)?
   - Error/warning list (output)?

5. **Manufacturing Context:** Any specific protocols/standards?
   - IEC/IEEE standards?
   - Hardware communication patterns?
   - Real-time requirements?

---

## Conclusion

**simple_python is architecturally sound for manufacturing validation systems.**

Single codebase with three protocol targets:
- ✅ Flexible deployment (HTTP for cloud, IPC for local, gRPC for distributed)
- ✅ Unified testing (no "dead code")
- ✅ Maintainable (bugs fixed once, all targets inherit)
- ✅ Professional (shows customers multiple options)

**Ready for /eiffel-research skill to validate and refine.**

Estimated build: 4-5 days, 17,000-20,000 LOC.

**Status:** Ready to proceed.
