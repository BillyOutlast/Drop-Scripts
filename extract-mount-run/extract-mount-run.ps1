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
        (Get-Command 7z.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    if (-not $candidates) {
        throw "7-Zip (7z.exe) not found. Install 7-Zip or ensure 7z.exe is on PATH."
    }

    return $candidates[0]
}

try {
    $rarFullPath = Resolve-FullPath $RarPath
    if (-not (Test-Path $rarFullPath)) {
        throw "RAR file not found: $rarFullPath"
    }

    $workRoot = Join-Path -Path $env:TEMP -ChildPath ("rar_extract_" + [Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $workRoot | Out-Null

    $sevenZip = Get-7ZipPath
    & $sevenZip x -y -o"$workRoot" "$rarFullPath" | Out-Null

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
