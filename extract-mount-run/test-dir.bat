@echo off
setlocal EnableExtensions

:: Print the current path
echo %CD%

:: List the contents of the current directory
dir
timeout /t 10 /nobreak

endlocal
exit /b 0
