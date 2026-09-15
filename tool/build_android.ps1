$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot

$versionScript = Join-Path $PSScriptRoot "version.ps1"
. $versionScript
$versionInfo = Get-VersionInfo -ProjectRoot $projectRoot

Push-Location $projectRoot
try {
    Write-Host "==> fvm flutter build apk --release --split-per-abi"
    fvm flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) {
        Write-Error "flutter build apk failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

$apkDir = Join-Path $projectRoot "build\app\outputs\flutter-apk"
if (-not (Test-Path -LiteralPath $apkDir)) {
    Write-Error "APK directory not found: $apkDir"
    exit 1
}

$renamed = $false
Get-ChildItem -LiteralPath $apkDir -Filter "*.apk" -File | ForEach-Object {
    $match = [regex]::Match($_.Name, '^app(?:-(.+))?-(release|debug|profile)\.apk$')
    if ($match.Success) {
        $abi = $match.Groups[1].Value
        if ($abi) {
            $newName = "CPD-$($versionInfo.Display)-$abi.apk"
        } else {
            $newName = "CPD-$($versionInfo.Display).apk"
        }
        $newPath = Join-Path $_.DirectoryName $newName
        Move-Item -LiteralPath $_.FullName -Destination $newPath -Force
        Write-Host "==> Renamed: $($_.Name) -> $newName"
        $renamed = $true

        $sha1 = "$($_.FullName).sha1"
        if (Test-Path -LiteralPath $sha1) {
            Move-Item -LiteralPath $sha1 -Destination "$newPath.sha1" -Force
        }
    }
}

if (-not $renamed) {
    Write-Host "==> No APK needed renaming"
}
Write-Host "==> Android packaging completed"
