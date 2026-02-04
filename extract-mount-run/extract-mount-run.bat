@echo on
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Searching for RAR files in current directory...
    set "RAR_COUNT=0"
    for %%F in (*.rar) do (
        set /a "RAR_COUNT+=1"
        set "RAR_!RAR_COUNT!=%%F"
    )
    
    if !RAR_COUNT! equ 0 (
        echo Error: No RAR files found in current directory.
        exit /b 1
    )
    
    echo.
    echo Select a RAR file:
    for /l %%I in (1,1,!RAR_COUNT!) do (
        echo [%%I] !RAR_%%I!
    )
    echo.
    
    set /p RAR_SELECTION="Enter number (1-!RAR_COUNT!): "
    
    if not defined RAR_SELECTION (
        echo Error: No selection made.
        exit /b 1
    )
    
    if !RAR_SELECTION! lss 1 (
        echo Error: Invalid selection.
        exit /b 1
    )
    
    if !RAR_SELECTION! gtr !RAR_COUNT! (
        echo Error: Invalid selection.
        exit /b 1
    )
    
    for /f "delims=" %%A in ("!RAR_SELECTION!") do (
        set "RAR_FILE=!RAR_%%A!"
    )
) else (
    set "RAR_FILE=%~f1"
)

if "%~2"=="" (
    set "USER_SELECT_EXE=1"
) else (
    set "EXE_NAME=%~2"
)

:: Check if RAR file exists
if not exist "!RAR_FILE!" (
    echo Error: RAR file not found: !RAR_FILE!
    exit /b 1
)

:: Create temp directory for extraction
set "WORK_ROOT=%TEMP%\rar_extract_%RANDOM%_%RANDOM%"
mkdir "!WORK_ROOT!"
if errorlevel 1 (
    echo Error: Failed to create working directory
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
    exit /b 1
)

"!SEVEN_ZIP!" x -y -o"!WORK_ROOT!" "!RAR_FILE!"
if errorlevel 1 (
    echo Error: Failed to extract RAR file
    rmdir /s /q "!WORK_ROOT!"
    exit /b 1
)

:: Find ISO file using PowerShell
echo Looking for ISO file...
for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "Get-ChildItem -Path '!WORK_ROOT!' -Filter *.iso -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName"') do (
    set "ISO_FILE=%%A"
)

if not defined ISO_FILE (
    echo Error: No ISO file found in extracted contents
    echo Contents of working directory:
    dir /s "!WORK_ROOT!"
    rmdir /s /q "!WORK_ROOT!"
    exit /b 1
)

echo Found ISO: !ISO_FILE!

echo Found ISO: !ISO_FILE!

:: Mount ISO using PowerShell
echo Mounting ISO...
for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "try { $img = Mount-DiskImage -ImagePath '!ISO_FILE!' -PassThru; ($img ^| Get-Volume).DriveLetter + ':' } catch { exit 1 }"') do set "MOUNT_DRIVE=%%A"

if not defined MOUNT_DRIVE (
    echo Error: Failed to mount ISO
    rmdir /s /q "!WORK_ROOT!"
    exit /b 1
)

echo ISO mounted to: !MOUNT_DRIVE!

:: If user needs to select EXE, show menu
if defined USER_SELECT_EXE (
    echo.
    echo Searching for executables...
    set "EXE_COUNT=0"
    for /r "!MOUNT_DRIVE!\" %%E in (*.exe) do (
        set /a "EXE_COUNT+=1"
        set "EXE_!EXE_COUNT!=%%E"
    )
    
    if !EXE_COUNT! equ 0 (
        echo Error: No EXE files found on mounted ISO.
        goto :cleanup
    )
    
    echo.
    echo Select an executable:
    for /l %%I in (1,1,!EXE_COUNT!) do (
        echo [%%I] !EXE_%%I!
    )
    echo.
    
    set /p EXE_SELECTION="Enter number (1-!EXE_COUNT!): "
    
    if not defined EXE_SELECTION (
        echo Error: No selection made.
        goto :cleanup
    )
    
    if !EXE_SELECTION! lss 1 (
        echo Error: Invalid selection.
        goto :cleanup
    )
    
    if !EXE_SELECTION! gtr !EXE_COUNT! (
        echo Error: Invalid selection.
        goto :cleanup
    )
    
    for /f "delims=" %%A in ("!EXE_SELECTION!") do (
        set "EXE_PATH=!EXE_%%A!"
    )
) else (
    :: Find and execute EXE
    echo Looking for executable: !EXE_NAME!
    set "EXE_PATH="
    for /r "!MOUNT_DRIVE!\" %%E in (!EXE_NAME!) do (
        set "EXE_PATH=%%E"
        goto :found_exe
    )
    
    :found_exe
    if not defined EXE_PATH (
        echo Error: Executable not found: !EXE_NAME!
        goto :cleanup
    )
)

echo Found executable: !EXE_PATH!
echo Executing...
"!EXE_PATH!"
set "EXE_EXITCODE=!ERRORLEVEL!"

:cleanup
echo Unmounting ISO...
powershell.exe -NoProfile -Command "Dismount-DiskImage -ImagePath '!ISO_FILE!'" >nul 2>&1

echo Cleaning up temporary files...
rmdir /s /q "!WORK_ROOT!" >nul 2>&1

if defined EXE_EXITCODE (
    exit /b !EXE_EXITCODE!
) else (
    exit /b 1
)

endlocal
