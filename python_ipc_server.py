#!/usr/bin/env python3
"""
Windows Named Pipe IPC server for simple_python integration tests.

Creates a named pipe at \.\pipe\simple_python_ipc
Receives messages and echoes them back (framed with 4-byte big-endian length prefix).
"""

import json
import sys
import struct
import threading
import time
import win32pipe
import win32file
import win32con
import pywintypes

class IPCServer:
    """Windows Named Pipe IPC server."""
    
    def __init__(self, pipe_name=r"\.\pipe\simple_python_ipc"):
        self.pipe_name = pipe_name
        self.running = True
        self.connections = []
    
    def create_pipe(self):
        """Create the named pipe."""
        try:
            pipe = win32pipe.CreateNamedPipe(
                self.pipe_name,
                win32pipe.PIPE_ACCESS_DUPLEX,
                win32pipe.PIPE_TYPE_BYTE | win32pipe.PIPE_READMODE_BYTE,
                win32pipe.PIPE_UNLIMITED_INSTANCES,
                65536,  # output buffer size
                65536,  # input buffer size
                0,      # timeout
                None    # security attributes
            )
            return pipe
        except pywintypes.error as e:
            print(f"Error creating pipe: {e}", file=sys.stderr)
            return None
    
    def handle_connection(self, pipe_handle):
        """Handle a single client connection."""
        try:
            while self.running:
                # Read 4-byte length prefix
                length_data = win32file.ReadFile(pipe_handle, 4)[1]
                if not length_data or len(length_data) < 4:
                    break
                
                message_length = struct.unpack('>I', length_data)[0]
                print(f"Received message length: {message_length}", file=sys.stderr)
                
                # Read message body
                message_data = win32file.ReadFile(pipe_handle, message_length)[1]
                message_str = message_data.decode('utf-8')
                print(f"Received message: {message_str}", file=sys.stderr)
                
                # Parse and echo back
                try:
                    data = json.loads(message_str)
                    response = {
                        "status": "received",
                        "echoed": data,
                        "message": "Message received via IPC"
                    }
                except json.JSONDecodeError:
                    response = {
                        "status": "error",
                        "message": "Invalid JSON in IPC message"
                    }
                
                # Send response back
                response_str = json.dumps(response)
                response_bytes = response_str.encode('utf-8')
                response_frame = struct.pack('>I', len(response_bytes)) + response_bytes
                
                win32file.WriteFile(pipe_handle, response_frame)
                print(f"Sent response: {response_str}", file=sys.stderr)
        
        except Exception as e:
            print(f"Error handling connection: {e}", file=sys.stderr)
        finally:
            win32file.CloseHandle(pipe_handle)
    
    def run(self):
        """Run the server."""
        print(f"Starting IPC server on {self.pipe_name}", file=sys.stderr)
        sys.stderr.flush()
        
        try:
            while self.running:
                # Create pipe for this connection
                pipe = self.create_pipe()
                if not pipe:
                    time.sleep(1)
                    continue
                
                # Wait for connection
                win32pipe.ConnectNamedPipe(pipe, None)
                print(f"Client connected", file=sys.stderr)
                sys.stderr.flush()
                
                # Handle connection in thread
                thread = threading.Thread(target=self.handle_connection, args=(pipe,))
                thread.daemon = True
                thread.start()
                self.connections.append(thread)
        
        except KeyboardInterrupt:
            print("\nShutting down server...", file=sys.stderr)
            self.running = False
        except Exception as e:
            print(f"Server error: {e}", file=sys.stderr)
            self.running = False


def main():
    """Start the IPC server."""
    server = IPCServer()
    try:
        server.run()
    except KeyboardInterrupt:
        server.running = False


if __name__ == '__main__':
    main()
