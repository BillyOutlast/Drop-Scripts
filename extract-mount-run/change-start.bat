@echo on
setlocal enabledelayedexpansion
set "ORIGINAL_DIR=%CD%"
set "SCRIPT_DIR=%~dp0"
set "DROP_START_FILE=!ORIGINAL_DIR!\drop-start.txt"
start "Run Select" cmd.exe /c "cd /d \"!ORIGINAL_DIR!\" ^& run-select.bat"
endlocal
