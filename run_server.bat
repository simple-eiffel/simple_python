@echo off
REM Start the Python HTTP test server on port 8889
REM Run this BEFORE running the Eiffel tests

cd /d "%~dp0"

echo [STARTUP] Starting Python HTTP test server on port 8889...
echo [STARTUP] Keep this window open while running tests

python3 python_test_server.py --port 8889

if errorlevel 1 (
    echo [ERROR] Failed to start Python server
    echo [ERROR] Make sure python3 is installed and in your PATH
    pause
    exit /b 1
)
