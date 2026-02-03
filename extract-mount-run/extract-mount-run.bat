@echo off
setlocal EnableExtensions
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "extract-mount-run.ps1"
if errorlevel 1 goto :error
endlocal
exit /b 0

:error
set "EXITCODE=%ERRORLEVEL%"
echo Script failed with exit code %EXITCODE%.
endlocal
exit /b %EXITCODE%
