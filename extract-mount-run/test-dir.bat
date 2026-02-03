@echo off
setlocal EnableExtensions

:: Check if directory argument was provided
if "%~1"=="" (
    echo Error: No directory specified.
    echo Usage: %~nx0 ^<directory^>
    exit /b 1
)

:: Change to the specified directory
cd /d "%~1" 2>nul
if errorlevel 1 (
    echo Error: Failed to change to directory: %~1
    exit /b 1
)

:: Print the current path
echo %CD%

endlocal
exit /b 0
