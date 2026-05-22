@echo off
REM Launcher for bump-version.ps1 — stamps ChiMesh.md with today's revision date and rebuilds ChiMesh.htm.

setlocal
set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bump-version.ps1" %*

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo bump-version failed with exit code %RC%.
    pause
)
exit /b %RC%
