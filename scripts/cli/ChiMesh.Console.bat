@echo off
REM ChiMesh Console launcher.
REM
REM No args  -> opens interactive menu.
REM With args -> dispatches directly, e.g.:
REM     ChiMesh.Console.bat provision chimesh-001
REM     ChiMesh.Console.bat healthcheck
REM     ChiMesh.Console.bat find-deals core

setlocal
set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%ChiMesh.Console.ps1" %*

set "RC=%ERRORLEVEL%"
if "%~1"=="" (
    REM Interactive session — don't auto-close.
    exit /b %RC%
)
if not "%RC%"=="0" (
    echo.
    echo ChiMesh.Console failed with exit code %RC%.
    pause
)
exit /b %RC%
