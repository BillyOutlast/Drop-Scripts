@echo off
setlocal EnableExtensions

if "%~1"=="" (
    echo Error: RAR file name required.
    echo Usage: %~nx0 ^<rar-file^> ^<exe-name^>
    exit /b 1
)

if "%~2"=="" (
    echo Error: EXE name required.
    echo Usage: %~nx0 ^<rar-file^> ^<exe-name^>
    exit /b 1
)

set "RAR_FILE=%~f1"
set "EXE_NAME=%~2"

:: Check if RAR file exists
if not exist "%RAR_FILE%" (
    echo Error: RAR file not found: %RAR_FILE%
    exit /b 1
)

:: Create temp directory for extraction
set "WORK_ROOT=%TEMP%\rar_extract_%RANDOM%_%RANDOM%"
mkdir "%WORK_ROOT%"
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
    rmdir /s /q "%WORK_ROOT%"
    exit /b 1
)

"%SEVEN_ZIP%" x -y -o"%WORK_ROOT%" "%RAR_FILE%"
if errorlevel 1 (
    echo Error: Failed to extract RAR file
    rmdir /s /q "%WORK_ROOT%"
    exit /b 1
)

:: Find ISO file
echo Looking for ISO file...
set "ISO_FILE="
for /r "%WORK_ROOT%" %%I in (*.iso) do (
    set "ISO_FILE=%%I"
    goto :found_iso
)

:found_iso
if not defined ISO_FILE (
    echo Error: No ISO file found in extracted contents
    rmdir /s /q "%WORK_ROOT%"
    exit /b 1
)

echo Found ISO: %ISO_FILE%

:: Mount ISO using PowerShell
echo Mounting ISO...
for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "try { $img = Mount-DiskImage -ImagePath '%ISO_FILE%' -PassThru; ($img ^| Get-Volume).DriveLetter + ':' } catch { exit 1 }"') do set "MOUNT_DRIVE=%%A"

if not defined MOUNT_DRIVE (
    echo Error: Failed to mount ISO
    rmdir /s /q "%WORK_ROOT%"
    exit /b 1
)

echo ISO mounted to: %MOUNT_DRIVE%

:: Find and execute EXE
echo Looking for executable: %EXE_NAME%
set "EXE_PATH="
for /r "%MOUNT_DRIVE%\" %%E in (%EXE_NAME%) do (
    set "EXE_PATH=%%E"
    goto :found_exe
)

:found_exe
if not defined EXE_PATH (
    echo Error: Executable not found: %EXE_NAME%
    goto :cleanup
)

echo Found executable: %EXE_PATH%
echo Executing...
"%EXE_PATH%"
set "EXE_EXITCODE=%ERRORLEVEL%"

:cleanup
echo Unmounting ISO...
powershell.exe -NoProfile -Command "Dismount-DiskImage -ImagePath '%ISO_FILE%'" >nul 2>&1

echo Cleaning up temporary files...
rmdir /s /q "%WORK_ROOT%" >nul 2>&1

if defined EXE_EXITCODE (
    exit /b %EXE_EXITCODE%
) else (
    exit /b 1
)

endlocal
