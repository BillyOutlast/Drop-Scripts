@echo on
setlocal enabledelayedexpansion
set "ORIGINAL_DIR=%CD%"
set "SCRIPT_DIR=%~dp0"
set "DROP_START_FILE=!ORIGINAL_DIR!\drop-start.txt"
if exist "!DROP_START_FILE!" (
	set "DROP_START_CMD="
	for /f "usebackq delims=" %%A in ("!DROP_START_FILE!") do (
		set "DROP_START_CMD=%%A"
		goto :run_drop_start_cmd
	)
	:run_drop_start_cmd
	if defined DROP_START_CMD (
		call "!DROP_START_CMD!"
	)
	goto :end
) else (
	start "Run Select" cmd.exe /c "cd /d \"!ORIGINAL_DIR!\" ^& run-select.bat"
)
:end
endlocal
