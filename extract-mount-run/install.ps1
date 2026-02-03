#Requires -RunAsAdministrator

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

if ($currentPath -like "*$scriptDir*") {
    Write-Host "Script directory is already in system PATH." -ForegroundColor Green
    Write-Host "Path: $scriptDir" -ForegroundColor Cyan
    exit 0
}

$newPath = $currentPath + ";" + $scriptDir

try {
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "Successfully added to system PATH:" -ForegroundColor Green
    Write-Host $scriptDir -ForegroundColor Cyan
    Write-Host "`nYou may need to restart your terminal for changes to take effect." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to update PATH: $_"
    exit 1
}
