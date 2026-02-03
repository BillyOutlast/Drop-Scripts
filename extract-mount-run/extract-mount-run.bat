@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%extract-mount-run.ps1" "%CD%" %*
set "EXITCODE=%ERRORLEVEL%"
if not "%EXITCODE%"=="0" (
  echo Script failed with exit code %EXITCODE%.
  exit /b %EXITCODE%
)
endlocal
