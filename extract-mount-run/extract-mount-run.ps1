$ErrorActionPreference = 'Stop'

$targetDir = $null
if ($Dir) {
    $targetDir = $Dir
} elseif ($env:dir) {
    $targetDir = $env:dir
}

if ($targetDir) {
    if (-not (Test-Path -Path $targetDir)) {
        throw "Directory not found: $targetDir"
    }
    Set-Location -Path (Resolve-Path -Path $targetDir).Path
}

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

function Select-RarFromDirectory([string]$DirectoryPath) {
    $rarFiles = Get-ChildItem -Path $DirectoryPath -Filter *.rar -File | Sort-Object Name
    if (-not $rarFiles -or $rarFiles.Count -eq 0) {
        throw "No RAR files found in: $DirectoryPath"
    }

    Write-Host "Select a RAR file:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $rarFiles.Count; $i++) {
        $index = $i + 1
        Write-Host ("[{0}] {1}" -f $index, $rarFiles[$i].Name)
    }

    while ($true) {
        $selection = Read-Host "Enter number (1-$($rarFiles.Count))"
        if ([int]::TryParse($selection, [ref]$null)) {
            $selectedIndex = [int]$selection
            if ($selectedIndex -ge 1 -and $selectedIndex -le $rarFiles.Count) {
                return $rarFiles[$selectedIndex - 1].FullName
            }
        }
        Write-Host "Invalid selection. Please try again." -ForegroundColor Yellow
    }
}

try {
    if (-not $RarPath) {
        $RarPath = Select-RarFromDirectory (Get-Location).Path
    }

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

    if (-not $ExeName) {
        $mountRoot = ($volume.DriveLetter + ":\")
        $exeFiles = Get-ChildItem -Path $mountRoot -Filter *.exe -File | Sort-Object Name
        if (-not $exeFiles -or $exeFiles.Count -eq 0) {
            throw "No EXE files found in mounted ISO root: $mountRoot"
        }

        Write-Host "Select an executable to run:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $exeFiles.Count; $i++) {
            $index = $i + 1
            Write-Host ("[{0}] {1}" -f $index, $exeFiles[$i].Name)
        }

        while ($true) {
            $selection = Read-Host "Enter number (1-$($exeFiles.Count))"
            if ([int]::TryParse($selection, [ref]$null)) {
                $selectedIndex = [int]$selection
                if ($selectedIndex -ge 1 -and $selectedIndex -le $exeFiles.Count) {
                    $ExeName = $exeFiles[$selectedIndex - 1].Name
                    break
                }
            }
            Write-Host "Invalid selection. Please try again." -ForegroundColor Yellow
        }
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

Start-Sleep -Seconds 10
