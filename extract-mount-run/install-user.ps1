$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -like "*$scriptDir*") {
    Write-Host "Script directory is already in user PATH." -ForegroundColor Green
    Write-Host "Path: $scriptDir" -ForegroundColor Cyan
    exit 0
}

if ($currentPath) {
    $newPath = $currentPath + ";" + $scriptDir
} else {
    $newPath = $scriptDir
}

try {
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Successfully added to user PATH:" -ForegroundColor Green
    Write-Host $scriptDir -ForegroundColor Cyan
    Write-Host "`nYou may need to restart your terminal for changes to take effect." -ForegroundColor Yellow
    Write-Host "After restarting terminal, you can run: extract-mount-run.ps1" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to update PATH: $_"
    exit 1
}
