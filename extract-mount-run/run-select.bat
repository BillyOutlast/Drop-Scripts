@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%CD%"
set "SCRIPT_DIR=%~dp0"
set "DROP_START_FILE=!ROOT_DIR!\drop-start.txt"
echo Scanning for executables under: !ROOT_DIR!
echo.

set "EXE_COUNT=0"
for /f "delims=" %%E in ('dir /s /b /a:-d "!ROOT_DIR!\*.exe" 2^>nul') do (
	set /a "EXE_COUNT+=1"
	set "EXE_!EXE_COUNT!=%%~fE"
)

if !EXE_COUNT! equ 0 (
	echo No executables found.
	pause
	exit /b 1
)

echo Executables found:
for /l %%I in (1,1,!EXE_COUNT!) do (
	echo [%%I] !EXE_%%I!
)

echo.
echo [0] Cancel
set /p EXE_SELECTION="Enter number (0 to cancel, 1-!EXE_COUNT!): "
if not defined EXE_SELECTION (
	echo Invalid selection.
	pause
	exit /b 1
)
if !EXE_SELECTION! equ 0 (
	echo Cancelled.
	pause
	exit /b 0
)
if !EXE_SELECTION! lss 1 (
	echo Invalid selection.
	pause
	exit /b 1
)
if !EXE_SELECTION! gtr !EXE_COUNT! (
	echo Invalid selection.
	pause
	exit /b 1
)
for /f "delims=" %%A in ("!EXE_SELECTION!") do (
	set "EXE_PATH=!EXE_%%A!"
)
echo Writing selection to !DROP_START_FILE!
>"!DROP_START_FILE!" echo !EXE_PATH!
echo Saved.
pause
endlocal
