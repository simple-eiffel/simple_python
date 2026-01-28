#!/usr/bin/env python3
"""
Simple Python test server for simple_python HTTP integration tests.

Provides three endpoints:
  POST /validate      - Receive Eiffel message and echo back
  POST /echo          - Echo the request body back
  GET /health         - Health check
"""

import json
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

class SimpleHTTPHandler(BaseHTTPRequestHandler):
    """HTTP request handler for test server."""

    def do_GET(self):
        """Handle GET requests."""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = json.dumps({"status": "ok", "server": "simple_python_test"})
            self.wfile.write(response.encode('utf-8'))
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = json.dumps({"error": "Not found"})
            self.wfile.write(response.encode('utf-8'))

    def do_POST(self):
        """Handle POST requests."""
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')

        if self.path == '/validate':
            # Echo back what we received
            try:
                data = json.loads(body) if body else {}
                response = {
                    "status": "received",
                    "echoed": data,
                    "message": "Message received and validated"
                }
            except json.JSONDecodeError:
                response = {
                    "status": "error",
                    "message": "Invalid JSON received"
                }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))

        elif self.path == '/echo':
            # Echo the raw body back
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            if body:
                self.wfile.write(body.encode('utf-8'))
            else:
                self.wfile.write(json.dumps({"echo": ""}).encode('utf-8'))
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = json.dumps({"error": f"Endpoint {self.path} not found"})
            self.wfile.write(response.encode('utf-8'))

    def log_message(self, format, *args):
        """Log to stderr instead of stdout."""
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), format % args))
        sys.stderr.flush()


def main():
    """Start the test HTTP server."""
    host = "127.0.0.1"
    port = 8888
    
    server = HTTPServer((host, port), SimpleHTTPHandler)
    print(f"Starting simple_python test server on http://{host}:{port}", file=sys.stderr)
    print(f"Endpoints: POST /validate, POST /echo, GET /health", file=sys.stderr)
    sys.stderr.flush()
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...", file=sys.stderr)
        server.shutdown()


if __name__ == '__main__':
    main()
