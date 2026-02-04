@echo off
setlocal

echo.
echo Installing extract-mount-run to user PATH...
echo.

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

:: Remove trailing backslash for cleaner path
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo Script directory: %SCRIPT_DIR%

:: Check if directory is already in PATH
for /f "tokens=*" %%A in ('powershell.exe -NoProfile -Command "([System.Environment]::GetEnvironmentVariable('Path', 'User')).Split(';') | Where-Object { $_ -eq '%SCRIPT_DIR%' }" 2^>nul') do (
    echo.
    echo This directory is already in your PATH!
    exit /b 0
)

:: Add to user PATH using PowerShell
echo Adding directory to PATH...
powershell.exe -NoProfile -Command ^
    "try { " ^
    "$currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'User'); " ^
    "$newPath = $currentPath + ';%SCRIPT_DIR%'; " ^
    "[System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User'); " ^
    "Write-Host 'SUCCESS: Directory added to PATH!'; " ^
    "Write-Host 'Please restart your terminal or command prompt for changes to take effect.'; " ^
    "} catch { " ^
    "Write-Host 'ERROR: Failed to add to PATH'; " ^
    "exit 1; " ^
    "}"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to add directory to PATH
    exit /b 1
)

echo.
echo Installation complete!
echo You can now run 'extract-mount-run' from any directory.
echo.

endlocal
