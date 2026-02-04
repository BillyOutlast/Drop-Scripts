setlocal EnableExtensions



:: Print the current path
echo %CD%
dir
echo %~1


:: List the contents of the current directory
timeout /t 10 /nobreak

endlocal
exit /b 0
