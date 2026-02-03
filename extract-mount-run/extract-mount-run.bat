setlocal EnableExtensions



:: Print the current path
echo %~1
:: echo %CD%

:: List the contents of the current directory
:: dir
timeout /t 10 /nobreak

endlocal
exit /b 0
