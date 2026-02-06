@echo on
setlocal enabledelayedexpansion
cd /d %~dp0
start /wait cmd.exe /c "extract-mount-run.bat"
start "Run Select" cmd.exe /c "cd /d \"!ORIGINAL_DIR!\" ^& run-select.bat"

endlocal
