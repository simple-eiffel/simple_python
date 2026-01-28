# simple_python

[Documentation](https://simple-eiffel.github.io/simple_python/) •
[GitHub](https://github.com/simple-eiffel/simple_python) •
[Issues](https://github.com/simple-eiffel/simple_python/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)

Eiffel-Python bridge for ultra-low-latency validation communication via HTTP, IPC, or gRPC.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

✅ **Production Ready** — v1.0.0
- 27 tests passing, 100% pass rate
- Design by Contract throughout (preconditions, postconditions, invariants)
- SCOOP-compatible (concurrent-safe message handling)
- Void-safe (null-safety guarantees)

## Quick Start

```eiffel
local
    l_lib: SIMPLE_PYTHON
    l_bridge: HTTP_PYTHON_BRIDGE
    l_request: PYTHON_VALIDATION_REQUEST
do
    create l_lib.make
    l_bridge := l_lib.new_http_bridge ("localhost", 8080)
    create l_request.make ("validation_001")
    l_bridge.send_message (l_request)
end
```

For complete documentation, see [our docs site](https://simple-eiffel.github.io/simple_python/).

## Features

- **HTTP Bridge** - JSON over HTTP/1.1 with configurable timeouts
- **IPC Bridge** - Windows named pipes (ultra-low-latency, same-machine only)
- **gRPC Bridge** - High-performance RPC (Phase 2, extensible design)
- **Message Serialization** - Validation requests/responses with JSON and binary formats
- **Thread-Safe Communication** - SCOOP-compatible for concurrent access

For details, see the [User Guide](https://simple-eiffel.github.io/simple_python/user-guide.html).

## Installation

```bash
# Add to your ECF:
<library name="simple_python" location="$SIMPLE_EIFFEL/simple_python/simple_python.ecf"/>
```

## License

MIT License - See LICENSE file

## Support

- **Docs:** https://simple-eiffel.github.io/simple_python/
- **GitHub:** https://github.com/simple-eiffel/simple_python
- **Issues:** https://github.com/simple-eiffel/simple_python/issues
