#!/usr/bin/env python3
"""
Python test servers for simple_python Eiffel-Python bridge validation.

Implements three protocols:
- HTTP: JSON over HTTP/1.1
- IPC: Windows named pipes
- gRPC: (placeholder for Phase 2)
"""

import json
import struct
import threading
import socket
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime


class SimplepythonHTTPHandler(BaseHTTPRequestHandler):
    """HTTP handler implementing simple_python protocol."""

    def log_message(self, format, *args):
        """Suppress default HTTP logging."""
        pass

    def do_POST(self):
        """Handle POST request with simple_python message."""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length == 0:
                self.send_error(400, "Missing Content-Length")
                return

            body = self.rfile.read(content_length)

            # Decode message (4-byte length prefix + JSON)
            if len(body) < 4:
                self.send_error(400, "Message too short")
                return

            length = struct.unpack('>I', body[:4])[0]
            if len(body) < 4 + length:
                self.send_error(400, "Incomplete message")
                return

            json_data = body[4:4+length].decode('utf-8')
            request = json.loads(json_data)

            print(f"[HTTP] Received request: {request.get('message_id')}")

            # Validate request structure
            if 'message_id' not in request or 'type' not in request:
                self.send_error(400, "Missing required fields")
                return

            # Echo back as validation_response
            response = {
                'message_id': request['message_id'],
                'type': 'validation_response',
                'timestamp': datetime.now().isoformat(),
                'attributes': {
                    'result': 'PASS',
                    'score': 0.95,
                    'message': 'Validation passed'
                }
            }

            # Send response with 4-byte length prefix
            response_json = json.dumps(response)
            response_bytes = struct.pack('>I', len(response_json)) + response_json.encode('utf-8')

            self.send_response(200)
            self.send_header('Content-Length', str(len(response_bytes)))
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(response_bytes)

            print(f"[HTTP] Sent response: {response.get('message_id')}")

        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON")
        except Exception as e:
            print(f"[HTTP] Error: {e}")
            self.send_error(500, str(e))


class SimplepythonIPCServer:
    """IPC server using Windows named pipes."""

    def __init__(self, pipe_name):
        """Initialize IPC server with pipe name."""
        self.pipe_name = pipe_name
        self.running = False

    def start(self):
        """Start IPC server (stub for demonstration)."""
        print(f"[IPC] Starting server on {self.pipe_name}")
        print("[IPC] Note: Full IPC implementation requires Win32 API (pywin32)")
        # In production, use:
        # import win32pipe, win32file, pywintypes
        # Named pipe communication here
        self.running = True

    def stop(self):
        """Stop IPC server."""
        self.running = False
        print("[IPC] Server stopped")

    def handle_connection(self, pipe):
        """Handle single pipe connection."""
        try:
            # Read 4-byte length prefix
            length_bytes = pipe.read(4)
            if len(length_bytes) < 4:
                return

            length = struct.unpack('>I', length_bytes)[0]

            # Read payload
            json_data = pipe.read(length).decode('utf-8')
            request = json.loads(json_data)

            print(f"[IPC] Received request: {request.get('message_id')}")

            # Send response
            response = {
                'message_id': request['message_id'],
                'type': 'validation_response',
                'timestamp': datetime.now().isoformat(),
                'attributes': {
                    'result': 'PASS',
                    'latency_ms': 5  # IPC is ultra-fast
                }
            }

            response_json = json.dumps(response)
            response_bytes = struct.pack('>I', len(response_json)) + response_json.encode('utf-8')
            pipe.write(response_bytes)

            print(f"[IPC] Sent response: {response.get('message_id')}")

        except Exception as e:
            print(f"[IPC] Connection error: {e}")


class SimplepythonGRPCServer:
    """gRPC server (Phase 2 placeholder)."""

    def __init__(self, host, port):
        """Initialize gRPC server."""
        self.host = host
        self.port = port

    def start(self):
        """Start gRPC server (stub)."""
        print(f"[gRPC] Starting server on {self.host}:{self.port}")
        print("[gRPC] Note: Full gRPC implementation requires grpcio and protobuf")
        # In production, use:
        # from concurrent import futures
        # import grpc
        # Define service with simple_python.proto


def run_http_server(host='localhost', port=8080):
    """Run HTTP test server."""
    print(f"\n{'='*60}")
    print(f"simple_python HTTP Test Server")
    print(f"{'='*60}")
    print(f"Listening on {host}:{port}")
    print("Waiting for validation requests...")
    print("(Press Ctrl+C to stop)\n")

    server = HTTPServer((host, port), SimplepythonHTTPHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[HTTP] Shutting down...")
        server.shutdown()


def run_ipc_server(pipe_name=r'\\.\pipe\eiffel_python_ipc'):
    """Run IPC test server."""
    print(f"\n{'='*60}")
    print(f"simple_python IPC Test Server")
    print(f"{'='*60}")
    print(f"Listening on {pipe_name}")
    print("Waiting for validation requests...")
    print("(Press Ctrl+C to stop)\n")

    server = SimplepythonIPCServer(pipe_name)
    server.start()
    try:
        while server.running:
            # IPC pipe listening would go here
            # (requires pywin32 for actual implementation)
            threading.Event().wait(1)
    except KeyboardInterrupt:
        print("\n[IPC] Shutting down...")
        server.stop()


def run_grpc_server(host='localhost', port=50051):
    """Run gRPC test server."""
    print(f"\n{'='*60}")
    print(f"simple_python gRPC Test Server")
    print(f"{'='*60}")
    print(f"Listening on {host}:{port}")
    print("Waiting for validation requests...")
    print("(Press Ctrl+C to stop)\n")

    server = SimplepythonGRPCServer(host, port)
    server.start()
    try:
        threading.Event().wait()
    except KeyboardInterrupt:
        print("\n[gRPC] Shutting down...")


def main():
    """Run test servers based on command-line argument."""
    if len(sys.argv) < 2:
        print("Usage: python3 python_servers.py <protocol>")
        print("\nProtocols:")
        print("  http                 - HTTP/1.1 JSON server (default)")
        print("  ipc                  - Windows named pipe server")
        print("  grpc                 - gRPC server (Phase 2)")
        print("\nExamples:")
        print("  python3 python_servers.py http")
        print("  python3 python_servers.py ipc")
        print("  python3 python_servers.py grpc")
        sys.exit(1)

    protocol = sys.argv[1].lower()

    if protocol == 'http':
        run_http_server()
    elif protocol == 'ipc':
        run_ipc_server()
    elif protocol == 'grpc':
        run_grpc_server()
    else:
        print(f"Unknown protocol: {protocol}")
        sys.exit(1)


if __name__ == '__main__':
    main()
