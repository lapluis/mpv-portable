@echo off
setlocal

set "psExe=powershell.exe"
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
    set "psExe=%ProgramFiles%\PowerShell\7\pwsh.exe"
)

where.exe pwsh.exe >nul 2>&1 && (
    set "psExe=pwsh.exe"
)

"%psExe%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-mpv.ps1"
set "updateExitCode=%errorlevel%"

pause
exit /b %updateExitCode%
