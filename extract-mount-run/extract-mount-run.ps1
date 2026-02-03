param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RarPath,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$ExeName
)

$ErrorActionPreference = 'Stop'

function Resolve-FullPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -Path $Path).Path
    }
    return (Resolve-Path -Path (Join-Path -Path (Get-Location) -ChildPath $Path)).Path
}

function Get-7ZipPath {
    $candidates = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )
    
    $cmdPath = Get-Command 7z.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
    if ($cmdPath) {
        $candidates = @($cmdPath) + $candidates
    }
    
    $found = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $found) {
        throw "7-Zip (7z.exe) not found. Install 7-Zip or ensure 7z.exe is on PATH."
    }

    return $found
}

try {
    $rarFullPath = Resolve-FullPath $RarPath
    if (-not (Test-Path $rarFullPath)) {
        throw "RAR file not found: $rarFullPath"
    }

    $workRoot = Join-Path -Path $env:TEMP -ChildPath ("rar_extract_" + [Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $workRoot | Out-Null

    $sevenZip = Get-7ZipPath
    Write-Host "Using 7-Zip at: $sevenZip"
    
    if (-not (Test-Path $sevenZip)) {
        throw "7-Zip executable not found at: $sevenZip"
    }
    
    $extractArgs = @('x', '-y', "-o$workRoot", $rarFullPath)
    $process = Start-Process -FilePath $sevenZip -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        throw "7-Zip extraction failed with exit code: $($process.ExitCode)"
    }

    $iso = Get-ChildItem -Path $workRoot -Recurse -Filter *.iso | Select-Object -First 1
    if (-not $iso) {
        throw "No ISO found after extraction."
    }

    $diskImage = Mount-DiskImage -ImagePath $iso.FullName -PassThru
    $volume = ($diskImage | Get-Volume | Select-Object -First 1)
    if (-not $volume -or -not $volume.DriveLetter) {
        throw "Failed to determine mounted drive letter."
    }

    $exePath = Join-Path -Path ($volume.DriveLetter + ":\") -ChildPath $ExeName
    if (-not (Test-Path $exePath)) {
        throw "Executable not found in ISO: $exePath"
    }

    Start-Process -FilePath $exePath
}
finally {
    if ($diskImage) {
        Dismount-DiskImage -ImagePath $diskImage.ImagePath -ErrorAction SilentlyContinue
    }

    if ($workRoot -and (Test-Path $workRoot)) {
        Remove-Item -Path $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
