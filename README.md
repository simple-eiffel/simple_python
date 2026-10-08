# simple_python

[Documentation](https://simple-eiffel.github.io/simple_python/) •
[GitHub](https://github.com/simple-eiffel/simple_python) •
[Issues](https://github.com/simple-eiffel/simple_python/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)

Production-ready Eiffel-Python bridge for control board validation and orchestration via HTTP, IPC, or gRPC.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

✅ **Production Ready** — v1.0.0
- 34 tests passing, 100% pass rate
- HTTP, IPC, and gRPC communication bridges
- Design by Contract throughout

## Quick Start

```eiffel
local
    l_bridge: HTTP_PYTHON_BRIDGE
    l_request: PYTHON_VALIDATION_REQUEST
do
    create l_bridge.make_with_host_port ("127.0.0.1", 8889)
    create l_request.make ("validation_001")
    if l_bridge.initialize then
        if l_bridge.send_message (l_request) then
            io.put_string ("Validation successful")
        end
        l_bridge.close
    end
end
```

For complete documentation, see [our docs site](https://simple-eiffel.github.io/simple_python/).

## Features

- HTTP bridge for REST-based validation
- IPC bridge: loopback TCP (127.0.0.1:9001), 4-byte big-endian length + UTF-8 JSON frames, via simple_net
- gRPC bridge: the same framing over TCP to any host (default port 9002); not HTTP/2 gRPC
- Full Design by Contract with MML postconditions
- SCOOP-compatible concurrent messaging

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
