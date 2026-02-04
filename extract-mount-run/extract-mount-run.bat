@echo off
setlocal enabledelayedexpansion

:: Clear and initialize debug log
set "DEBUG_LOG=%CD%\debug.log"
del /f /q "!DEBUG_LOG!" 2>nul
echo [%date% %time%] Script started >> "!DEBUG_LOG!"

:: Save the original directory
set "ORIGINAL_DIR=%CD%"

if "%~1"=="" (
    goto :start_menu
) else (
    set "RAR_FILE=%~f1"
    goto :after_rar_selection
)

:start_menu
echo.
echo Select mode:
echo [1] Search for RAR files
echo [2] Search for EXE files
echo [0] Exit
echo.
set /p START_SELECTION="Enter number (0-2): "
if not defined START_SELECTION (
    echo Invalid selection.
    goto :start_menu
)
if !START_SELECTION! equ 0 (
    exit /b 0
)
if !START_SELECTION! equ 1 (
    goto :rar_selection_loop
)
if !START_SELECTION! equ 2 (
    set "EXE_SEARCH_DIR=!ORIGINAL_DIR!"
    goto :exe_selection_loop
)
echo Invalid selection.
goto :start_menu

:rar_selection_loop
cd /d "!ORIGINAL_DIR!"
set "RAR_FILE="
set "RAR_SELECTION="
set "SELECTED_RAR="

:: Clear previous RAR variables
for /f "tokens=1* delims==" %%A in ('set RAR_ 2^>nul') do set "%%A="

echo Searching for RAR files in current directory...
echo [%time%] Searching for RAR files in: !ORIGINAL_DIR! >> "!DEBUG_LOG!"
set "RAR_COUNT=0"
for %%F in (*.rar) do (
    set /a "RAR_COUNT+=1"
    set "RAR_!RAR_COUNT!=%%~fF"
    echo [%time%] Found RAR #!RAR_COUNT!: %%~fF >> "!DEBUG_LOG!"
)

if !RAR_COUNT! equ 0 (
    echo No RAR files found in current directory.
    set "EXE_SEARCH_DIR=!ORIGINAL_DIR!"
    goto :exe_selection_loop
)

goto :rar_menu

:exe_selection_loop
echo.
echo Executables found in !EXE_SEARCH_DIR!:
set "EXE_COUNT=0"
for /f "delims=" %%E in ('where /r "!EXE_SEARCH_DIR!" *.exe 2^>nul') do (
    set /a "EXE_COUNT+=1"
    set "EXE_!EXE_COUNT!=%%~fE"
)
if !EXE_COUNT! equ 0 (
    for /f "delims=" %%E in ('dir /b /a:-d "!EXE_SEARCH_DIR!\*.exe" 2^>nul') do (
        set /a "EXE_COUNT+=1"
        set "EXE_!EXE_COUNT!=!EXE_SEARCH_DIR!\%%E"
    )
)
if !EXE_COUNT! equ 0 (
    echo (none^)
    pause
    goto :start_menu
)
echo [0] Exit
for /l %%I in (1,1,!EXE_COUNT!) do (
    echo [%%I] !EXE_%%I!
)
echo.
set /p EXE_SELECTION="Enter number (0 to exit, 1-!EXE_COUNT!): "
if not defined EXE_SELECTION (
    echo Invalid selection.
    goto :exe_selection_loop
)
if !EXE_SELECTION! equ 0 (
    echo Exiting...
    goto :start_menu
)
if !EXE_SELECTION! lss 1 (
    echo Invalid selection.
    goto :exe_selection_loop
)
if !EXE_SELECTION! gtr !EXE_COUNT! (
    echo Invalid selection.
    goto :exe_selection_loop
)
for /f "delims=" %%A in ("!EXE_SELECTION!") do (
    set "EXE_PATH=!EXE_%%A!"
)
echo.
echo Found executable: !EXE_PATH!
echo Executing...
"!EXE_PATH!" /DIR="!ORIGINAL_DIR!"
set "EXE_EXITCODE=!ERRORLEVEL!"
echo.
echo Process completed with exit code !EXE_EXITCODE!.
goto :exe_selection_loop

:rar_menu

echo.
echo Select a RAR file:
echo [0] Exit
for /l %%I in (1,1,!RAR_COUNT!) do (
    echo [%%I] !RAR_%%I!
)
echo.

set /p RAR_SELECTION="Enter number (0 to exit, 1-!RAR_COUNT!): "
echo [%time%] User selected: !RAR_SELECTION! >> "!DEBUG_LOG!"

if not defined RAR_SELECTION (
    echo Invalid selection.
    echo [%time%] Invalid selection - RAR_SELECTION undefined >> "!DEBUG_LOG!"
    goto :rar_selection_loop
)

if !RAR_SELECTION! equ 0 (
    echo Exiting...
    echo [%time%] User exited >> "!DEBUG_LOG!"
    goto :start_menu
)

if !RAR_SELECTION! lss 1 (
    echo Invalid selection.
    echo [%time%] Invalid selection - !RAR_SELECTION! less than 1 >> "!DEBUG_LOG!"
    goto :rar_selection_loop
)

if !RAR_SELECTION! gtr !RAR_COUNT! (
    echo Invalid selection.
    echo [%time%] Invalid selection - !RAR_SELECTION! greater than !RAR_COUNT! >> "!DEBUG_LOG!"
    goto :rar_selection_loop
)

for %%X in (!RAR_SELECTION!) do set "RAR_FILE=!RAR_%%X!"
echo [%time%] Retrieved RAR_FILE: !RAR_FILE! >> "!DEBUG_LOG!"
if not defined RAR_FILE (
    echo Error: Failed to retrieve RAR file selection.
    echo [%time%] ERROR: Failed to retrieve RAR_FILE from RAR_!RAR_SELECTION! >> "!DEBUG_LOG!"
    goto :rar_selection_loop
)

:after_rar_selection

if "%~2"=="" (
    set "USER_SELECT_EXE=1"
) else (
    set "EXE_NAME=%~2"
)

:: Check if RAR file exists
if not exist "!RAR_FILE!" (
    echo Error: RAR file not found: !RAR_FILE!
    echo [%time%] ERROR: RAR file not found: !RAR_FILE! >> "!DEBUG_LOG!"
    if "%~1"=="" (
        goto :rar_selection_loop
    ) else (
        pause
        exit /b 1
    )
)

:: Create temp directory for extraction
set "WORK_ROOT=%TEMP%\rar_extract_%RANDOM%_%RANDOM%"
mkdir "!WORK_ROOT!"
if errorlevel 1 (
    echo Error: Failed to create working directory
    pause
    exit /b 1
)

echo Extracting RAR file...
:: Try 7-Zip first
set "SEVEN_ZIP="
if exist "C:\Program Files\7-Zip\7z.exe" set "SEVEN_ZIP=C:\Program Files\7-Zip\7z.exe"
if exist "C:\Program Files (x86)\7-Zip\7z.exe" set "SEVEN_ZIP=C:\Program Files (x86)\7-Zip\7z.exe"

if not defined SEVEN_ZIP (
    echo Error: 7-Zip not found. Please install 7-Zip or add 7z.exe to PATH.
    rmdir /s /q "!WORK_ROOT!"
    pause
    exit /b 1
)

"!SEVEN_ZIP!" x -y -o"!WORK_ROOT!" "!RAR_FILE!"
if errorlevel 1 (
    echo Error: Failed to extract RAR file
    rmdir /s /q "!WORK_ROOT!"
    pause
    exit /b 1
)

:: Find ISO file
echo Looking for ISO file...
set "ISO_FILE="
pushd "!WORK_ROOT!"
for /r . %%A in (*.iso) do (
    set "ISO_FILE=%%A"
    popd
    goto :iso_found
)
popd

:iso_found
if not defined ISO_FILE (
    echo No ISO file found in extracted contents
    echo Searching for executables in working directory...
    set "SEARCH_DIR=!WORK_ROOT!"
) else (
    echo Found ISO: !ISO_FILE!
    
    echo Found ISO: !ISO_FILE!
    
    :: Mount ISO using PowerShell
    echo Mounting ISO...
    for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "try { $img = Mount-DiskImage -ImagePath '!ISO_FILE!' -PassThru; ($img ^| Get-Volume).DriveLetter + ':' } catch { exit 1 }"') do set "MOUNT_DRIVE=%%A"
    
    if not defined MOUNT_DRIVE (
        echo Error: Failed to mount ISO
        rmdir /s /q "!WORK_ROOT!"
        pause
        exit /b 1
    )
    
    echo ISO mounted to: !MOUNT_DRIVE!
    set "SEARCH_DIR=!MOUNT_DRIVE!\"
)

:find_exe_in_dir
:: If user needs to select EXE, show menu
if defined USER_SELECT_EXE (
    :exe_select_loop_in_dir
    echo.
    echo Searching for executables...
    set "EXE_COUNT=0"
    pushd "!SEARCH_DIR!"
    for /r . %%E in (*.exe) do (
        set /a "EXE_COUNT+=1"
        set "EXE_!EXE_COUNT!=%%E"
    )
    popd
    
    if !EXE_COUNT! equ 0 (
        echo Error: No EXE files found in !SEARCH_DIR!.
        if "%~1"=="" (
            pause
        )
        goto :cleanup
    )
    
    echo.
    echo Select an executable:
    echo [0] Finish
    for /l %%I in (1,1,!EXE_COUNT!) do (
        echo [%%I] !EXE_%%I!
    )
    echo.
    
    set /p EXE_SELECTION="Enter number (0 to finish, 1-!EXE_COUNT!): "
    
    if not defined EXE_SELECTION (
        echo Error: No selection made.
        if "%~1"=="" (
            pause
        )
        goto :exe_select_loop_in_dir
    )
    
    if !EXE_SELECTION! equ 0 (
        goto :cleanup
    )
    
    if !EXE_SELECTION! lss 1 (
        echo Error: Invalid selection.
        if "%~1"=="" (
            pause
        )
        goto :exe_select_loop_in_dir
    )
    
    if !EXE_SELECTION! gtr !EXE_COUNT! (
        echo Error: Invalid selection.
        if "%~1"=="" (
            pause
        )
        goto :exe_select_loop_in_dir
    )
    
    for /f "delims=" %%A in ("!EXE_SELECTION!") do (
        set "EXE_PATH=!EXE_%%A!"
    )
) else (
    :: Find and execute EXE
    echo Looking for executable: !EXE_NAME!
    set "EXE_PATH="
    pushd "!SEARCH_DIR!"
    for /r . %%E in (!EXE_NAME!) do (
        set "EXE_PATH=%%E"
        goto :found_exe
    )
    popd
    
    :found_exe
    if not defined EXE_PATH (
        echo Error: Executable not found: !EXE_NAME!
        if "%~1"=="" (
            pause
        )
        goto :cleanup
    )
)

echo Found executable: !EXE_PATH!
echo Executing...
"!EXE_PATH!" /DIR="!ORIGINAL_DIR!"
set "EXE_EXITCODE=!ERRORLEVEL!"

if defined USER_SELECT_EXE (
    echo.
    echo Process completed with exit code !EXE_EXITCODE!.
    goto :exe_select_loop_in_dir
)



:cleanup
if defined ISO_FILE (
    echo Unmounting ISO...
    powershell.exe -NoProfile -Command "Dismount-DiskImage -ImagePath '!ISO_FILE!'" >nul 2>&1
)

echo Cleaning up temporary files...
rmdir /s /q "!WORK_ROOT!" >nul 2>&1

if defined EXE_EXITCODE (
    if "%~1"=="" (
        echo.
        echo Process completed. Returning to menu...
        echo.
        cd /d "!ORIGINAL_DIR!"
        goto :rar_selection_loop
    ) else (
        pause
        exit /b !EXE_EXITCODE!
    )
) else (
    if "%~1"=="" (
        echo.
        echo Process completed with errors. Returning to menu...
        echo.
        cd /d "!ORIGINAL_DIR!"
        goto :rar_selection_loop
    ) else (
        pause
        exit /b 1
    )
)


endlocal
