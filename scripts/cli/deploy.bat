@echo off
REM Build ChiMesh.htm and FTP-upload ChiMesh.md / ChiMesh.htm / index.htm
REM to the target configured in scripts\cli\deploy.settings.json.

setlocal
set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%deploy.ps1" %*

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo deploy failed with exit code %RC%.
    pause
)
exit /b %RC%
