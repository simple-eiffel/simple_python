@echo off
REM Start Python HTTP test server on specified port
REM Usage: start_server.bat <port>

setlocal enabledelayedexpansion

set PORT=%1
if "%PORT%"=="" set PORT=8888

REM Start Python server in background without blocking
start /B "" python3.exe "%~dp0python_test_server.py" --port %PORT%

REM Give server time to initialize
timeout /t 2 /nobreak

REM Return success
exit /b 0
