#!/usr/bin/env python3
"""
gRPC-like server using TCP sockets on localhost.
Listens on port 9002 (or specified port) and handles bidirectional message exchange.
Messages use 4-byte big-endian length prefix + JSON payload (same as IPC server).
"""

import socket
import struct
import sys
import json
from threading import Thread

class GRPCServer:
    def __init__(self, port=9002):
        self.port = port
        self.server = None
        self.running = False

    def start(self):
        """Start the gRPC server."""
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server.bind(('127.0.0.1', self.port))
        self.server.listen(5)
        self.running = True

        print(f"[STARTUP] gRPC server listening on 127.0.0.1:{self.port}", file=sys.stderr)
        sys.stderr.flush()

        while self.running:
            try:
                client, addr = self.server.accept()
                print(f"[INFO] Client connected: {addr}", file=sys.stderr)
                sys.stderr.flush()

                # Handle client in a thread
                Thread(target=self.handle_client, args=(client, addr), daemon=True).start()
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"[ERROR] Accept error: {e}", file=sys.stderr)
                sys.stderr.flush()

    def handle_client(self, client, addr):
        """Handle a single client connection."""
        try:
            while self.running:
                # Read 4-byte length prefix
                length_data = client.recv(4)
                if not length_data:
                    break

                length = struct.unpack('>I', length_data)[0]
                print(f"[DEBUG] Received length prefix: {length} bytes", file=sys.stderr)
                sys.stderr.flush()

                # Read payload
                payload = b''
                while len(payload) < length:
                    chunk = client.recv(min(4096, length - len(payload)))
                    if not chunk:
                        break
                    payload += chunk

                print(f"[DEBUG] Received payload: {len(payload)} bytes", file=sys.stderr)
                sys.stderr.flush()

                # Decode message
                try:
                    message_json = json.loads(payload.decode('utf-8'))
                    print(f"[INFO] Message received: {message_json.get('message_id', 'unknown')}", file=sys.stderr)
                    sys.stderr.flush()

                    # Send response with VALIDATION_RESPONSE format (same as HTTP)
                    response = {
                        "type": "VALIDATION_RESPONSE",
                        "message_id": message_json.get("message_id", "unknown"),
                        "attributes": {
                            "result": "PASS",
                            "message": "gRPC Message received and validated",
                            "echoed_message_id": message_json.get("message_id", "unknown")
                        }
                    }

                    response_json = json.dumps(response).encode('utf-8')
                    response_length = struct.pack('>I', len(response_json))

                    print(f"[INFO] Sending response: {len(response_json)} bytes", file=sys.stderr)
                    sys.stderr.flush()

                    client.sendall(response_length + response_json)

                except json.JSONDecodeError as e:
                    print(f"[ERROR] JSON decode error: {e}", file=sys.stderr)
                    sys.stderr.flush()
                    break

        except Exception as e:
            print(f"[ERROR] Client handler error: {e}", file=sys.stderr)
            sys.stderr.flush()
        finally:
            client.close()
            print(f"[INFO] Client disconnected: {addr}", file=sys.stderr)
            sys.stderr.flush()

    def stop(self):
        """Stop the server."""
        self.running = False
        if self.server:
            self.server.close()


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9002

    server = GRPCServer(port)
    try:
        server.start()
    except KeyboardInterrupt:
        print("\n[SHUTDOWN] gRPC server shutting down...", file=sys.stderr)
        sys.stderr.flush()
        server.stop()


if __name__ == '__main__':
    main()
