@echo off
REM Start the Python HTTP test server on port 8889
REM Run this BEFORE running the Eiffel tests

cd /d "%~dp0"

echo [STARTUP] Starting Python HTTP test server on port 8889...
echo [STARTUP] Keep this window open while running tests
echo.

REM Try using 'py' launcher first (most reliable on Windows)
py -3 python_test_server.py --port 8889

if errorlevel 1 (
    echo.
    echo [FALLBACK] Trying python3 command...
    python3 python_test_server.py --port 8889

    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to start Python server!
        echo [ERROR] Could not find python3 or py launcher
        echo [ERROR] Make sure Python 3 is installed
        pause
        exit /b 1
    )
)
