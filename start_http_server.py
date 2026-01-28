#!/usr/bin/env python3
"""
Start the Python HTTP test server in the background.
Usage: python3 start_http_server.py <port>
"""

import subprocess
import sys
import time
import socket

def is_port_open(port, timeout=1):
    """Check if a port is listening."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex(('127.0.0.1', port))
        sock.close()
        return result == 0
    except:
        return False

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8888

    # Find the actual directory where this script is located
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    script_path = os.path.join(script_dir, 'python_test_server.py')

    print(f"[LAUNCHER] Script directory: {script_dir}", file=sys.stderr)
    print(f"[LAUNCHER] Server script path: {script_path}", file=sys.stderr)
    print(f"[LAUNCHER] Server script exists: {os.path.exists(script_path)}", file=sys.stderr)
    sys.stderr.flush()

    # Start the server process in the background (detached from parent)
    try:
        # Windows-specific: use CREATE_NEW_PROCESS_GROUP to detach
        import os
        import ctypes

        # Start process with new process group so it survives parent exit
        creationflags = 0x00000200  # CREATE_NEW_PROCESS_GROUP

        process = subprocess.Popen(
            [sys.executable, script_path, '--port', str(port)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=creationflags,
            cwd=os.path.dirname(__file__)
        )

        print(f"[LAUNCHER] Started Python server (PID: {process.pid}) on port {port}")
        sys.stderr.flush()

        # Wait for server to be listening
        for i in range(20):  # Try for up to 10 seconds
            if is_port_open(port):
                print(f"[LAUNCHER] Server is listening on port {port}")
                sys.stderr.flush()
                sys.exit(0)
            time.sleep(0.5)

        print(f"[LAUNCHER] WARNING: Server may not be listening after 10 seconds")
        sys.stderr.flush()
        sys.exit(0)  # Exit anyway - server might still start

    except Exception as e:
        print(f"[LAUNCHER] ERROR: Failed to start server: {e}")
        sys.stderr.flush()
        sys.exit(1)

if __name__ == '__main__':
    main()
