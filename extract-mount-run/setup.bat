@echo on
setlocal enabledelayedexpansion
cd /d %~dp0
start /wait cmd.exe /c "extract-mount-run.bat"
endlocal
