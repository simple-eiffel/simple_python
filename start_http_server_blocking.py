#!/usr/bin/env python3
"""
Start the Python HTTP test server and wait for it to be fully ready.
This is a blocking launcher - does not return until server is listening.
"""

import subprocess
import sys
import time
import socket
import os

def is_port_listening(port, timeout=1):
    """Check if a port is listening by attempting to connect."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex(('127.0.0.1', port))
        sock.close()
        return result == 0
    except Exception as e:
        print(f"[ERROR] Port check failed: {e}", file=sys.stderr)
        return False

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8889

    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    server_script = os.path.join(script_dir, 'python_test_server.py')

    print(f"[LAUNCHER] Starting server on port {port}...", file=sys.stderr)
    print(f"[LAUNCHER] Server script: {server_script}", file=sys.stderr)
    print(f"[LAUNCHER] Script exists: {os.path.exists(server_script)}", file=sys.stderr)
    sys.stderr.flush()

    # Start the server process with proper detachment
    try:
        # Windows-specific: use CREATE_NEW_PROCESS_GROUP to detach
        creationflags = 0x00000200  # CREATE_NEW_PROCESS_GROUP

        process = subprocess.Popen(
            [sys.executable, server_script, '--port', str(port)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=creationflags,
            cwd=script_dir
        )

        print(f"[LAUNCHER] Process started with PID {process.pid}", file=sys.stderr)
        sys.stderr.flush()

        # Wait for server to be listening
        print(f"[LAUNCHER] Waiting for server to listen on port {port}...", file=sys.stderr)
        sys.stderr.flush()

        for attempt in range(30):  # Try for up to 15 seconds
            if is_port_listening(port):
                print(f"[LAUNCHER] Server is listening! (attempt {attempt+1})", file=sys.stderr)
                sys.stderr.flush()
                print("READY")  # Signal to caller that server is ready
                sys.exit(0)

            if attempt % 5 == 0:
                print(f"[LAUNCHER] Still waiting... (attempt {attempt+1})", file=sys.stderr)
                sys.stderr.flush()

            time.sleep(0.5)

        print(f"[LAUNCHER] TIMEOUT: Server did not start listening within 15 seconds", file=sys.stderr)
        sys.stderr.flush()
        sys.exit(1)

    except Exception as e:
        print(f"[LAUNCHER] ERROR: {e}", file=sys.stderr)
        sys.stderr.flush()
        sys.exit(1)

if __name__ == '__main__':
    main()
