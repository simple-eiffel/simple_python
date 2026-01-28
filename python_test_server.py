#!/usr/bin/env python3
"""
Simple Python test server for simple_python HTTP integration tests.

Provides three endpoints:
  POST /validate      - Receive Eiffel message and echo back in PYTHON_MESSAGE format
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
        self.log_message("GET request to %s", self.path)
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = json.dumps({"status": "ok", "server": "simple_python_test"})
            self.wfile.write(response.encode('utf-8'))
            self.log_message("Health check: OK")
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = json.dumps({"error": "Not found"})
            self.wfile.write(response.encode('utf-8'))

    def do_POST(self):
        """Handle POST requests."""
        print("[DEBUG] do_POST called from NEW server version", file=sys.stderr)
        print(f"[DEBUG] Request path: '{self.path}' (type: {type(self.path)})", file=sys.stderr)
        sys.stderr.flush()
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')
        self.log_message("POST request to %s with %d bytes", self.path, len(body))
        self.log_message("Request body: %s", body[:200])  # Log first 200 chars

        if self.path == '/validate':
            # Parse request and send back PYTHON_MESSAGE format (type, message_id, attributes)
            print("[DEBUG] ENTERING /validate endpoint handler - SHOULD SEND VALIDATION_RESPONSE", file=sys.stderr)
            sys.stderr.flush()
            self.log_message("Processing /validate endpoint")
            try:
                data = json.loads(body) if body else {}
                message_id = data.get("message_id", "unknown")
                self.log_message("Received message_id: %s", message_id)

                # Send back proper PYTHON_MESSAGE format
                response = {
                    "type": "VALIDATION_RESPONSE",
                    "message_id": message_id,
                    "attributes": {
                        "result": "PASS",
                        "message": "Message received and validated",
                        "echoed_message_id": message_id
                    }
                }
                self.log_message("Sending VALIDATION_RESPONSE with message_id: %s", message_id)
            except json.JSONDecodeError as e:
                self.log_message("JSON parse error: %s", str(e))
                response = {
                    "type": "ERROR",
                    "message_id": "unknown",
                    "attributes": {
                        "error_code": "INVALID_JSON",
                        "error_message": "Invalid JSON received: " + str(e)
                    }
                }

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response_body = json.dumps(response)
            self.log_message("Response body: %s", response_body[:200])
            self.wfile.write(response_body.encode('utf-8'))
            self.log_message("Response sent successfully")

        elif self.path == '/echo':
            # Echo the raw body back
            self.log_message("Processing /echo endpoint")
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            if body:
                self.wfile.write(body.encode('utf-8'))
            else:
                self.wfile.write(json.dumps({"echo": ""}).encode('utf-8'))
            self.log_message("Echo response sent")
        else:
            self.log_message("Unknown endpoint: %s", self.path)
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

    print(f"[STARTUP] Starting simple_python test server on http://{host}:{port}", file=sys.stderr)
    print(f"[STARTUP] Endpoints: POST /validate, POST /echo, GET /health", file=sys.stderr)
    sys.stderr.flush()

    server = HTTPServer((host, port), SimpleHTTPHandler)
    print(f"[STARTUP] Server initialized, listening for connections", file=sys.stderr)
    sys.stderr.flush()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[SHUTDOWN] Shutting down server...", file=sys.stderr)
        sys.stderr.flush()
        server.shutdown()


if __name__ == '__main__':
    main()
