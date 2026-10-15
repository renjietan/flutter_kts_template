$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot

$versionScript = Join-Path $PSScriptRoot "version.ps1"
. $versionScript
$versionInfo = Get-VersionInfo -ProjectRoot $projectRoot

# ---------------------------------------------------------------------------
# Read the app display name and publisher from pubspec.yaml's top-level
# `inno_bundle` section, then reflect them into the Windows build before
# packaging. This makes the built/installed executable use the configured
# name (e.g. CPD) instead of the pubspec package name (flutter_kts_template).
# ---------------------------------------------------------------------------
function Get-InnoBundleString {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $pubspec = Join-Path $ProjectRoot 'pubspec.yaml'
    $inBlock = $false
    foreach ($line in [System.IO.File]::ReadAllLines($pubspec)) {
        if ($line -match '^inno_bundle\s*:') {
            $inBlock = $true
            continue
        }
        if ($inBlock) {
            # The inno_bundle block ends at the next non-indented top-level key.
            if ($line -match '^\S') {
                break
            }
            if ($line -match ('^\s*' + [regex]::Escape($Key) + '\s*:\s*(.+)$')) {
                return $Matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }
    return $null
}

function Get-PubspecName {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $pubspec = Join-Path $ProjectRoot 'pubspec.yaml'
    foreach ($line in [System.IO.File]::ReadAllLines($pubspec)) {
        if ($line -match '^name\s*:\s*(\S+)') {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return $null
}

$appName = Get-InnoBundleString -ProjectRoot $projectRoot -Key 'name'
if (-not $appName) {
    $appName = Get-PubspecName -ProjectRoot $projectRoot
}
if (-not $appName) {
    Write-Error "Unable to determine app name from pubspec.yaml"
    exit 1
}

$publisher = Get-InnoBundleString -ProjectRoot $projectRoot -Key 'publisher'
if (-not $publisher) {
    $publisher = 'com.example'
}

# Remove a stale old-named exe left over by a previous build so it cannot be
# packaged alongside the newly named executable.
$releaseDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
$staleExe = Join-Path $releaseDir 'flutter_kts_template.exe'
if (Test-Path -LiteralPath $staleExe) {
    Remove-Item -LiteralPath $staleExe -Force
    Write-Host "==> Removed stale: $staleExe"
}

$cmakePath = Join-Path $projectRoot 'windows\CMakeLists.txt'
$cmake = [System.IO.File]::ReadAllText($cmakePath)
$cmake = $cmake -replace 'project\([^ )]+ LANGUAGES CXX\)', "project($appName LANGUAGES CXX)"
$cmake = $cmake -replace 'set\(BINARY_NAME "[^"]+"\)', ('set(BINARY_NAME "' + $appName + '")')
[System.IO.File]::WriteAllText($cmakePath, $cmake)

$rcPath = Join-Path $projectRoot 'windows\runner\Runner.rc'
$rc = [System.IO.File]::ReadAllText($rcPath)
$rc = $rc -replace 'VALUE "CompanyName", "[^"]*"', ('VALUE "CompanyName", "' + $publisher + '"')
$rc = $rc -replace 'VALUE "FileDescription", "[^"]*"', ('VALUE "FileDescription", "' + $appName + '"')
$rc = $rc -replace 'VALUE "InternalName", "[^"]*"', ('VALUE "InternalName", "' + $appName + '"')
$rc = $rc -replace 'VALUE "OriginalFilename", "[^"]*"', ('VALUE "OriginalFilename", "' + $appName + '.exe"')
$rc = $rc -replace 'VALUE "ProductName", "[^"]*"', ('VALUE "ProductName", "' + $appName + '"')
$copyrightYear = (Get-Date).Year
$legalCopyright = "Copyright (C) $copyrightYear $publisher. All rights reserved."
$rc = $rc -replace 'VALUE "LegalCopyright", "[^"]*"', ('VALUE "LegalCopyright", "' + $legalCopyright + '"')
[System.IO.File]::WriteAllText($rcPath, $rc)

Write-Host "==> Applied app name '$appName' / publisher '$publisher' to Windows build"

# Copy the bundled Chinese language file into Inno Setup's Languages directory,
# so the fork's compiler:Languages\ChineseSimplified.isl can find it.
$innoLanguagesDirs = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\Languages'),
    'C:\Program Files (x86)\Inno Setup 6\Languages',
    'C:\Program Files\Inno Setup 6\Languages'
)
$targetLanguagesDir = $null
foreach ($dir in $innoLanguagesDirs) {
    if (Test-Path -LiteralPath $dir) {
        $targetLanguagesDir = $dir
        break
    }
}
if (-not $targetLanguagesDir) {
    Write-Error "Inno Setup Languages directory not found. Please install Inno Setup 6."
    exit 1
}
$bundledIsl = Join-Path $projectRoot 'installer\languages\ChineseSimplified.isl'
if (-not (Test-Path -LiteralPath $bundledIsl)) {
    Write-Error "Bundled ChineseSimplified.isl not found: $bundledIsl"
    exit 1
}
Copy-Item -LiteralPath $bundledIsl -Destination $targetLanguagesDir -Force
Write-Host "==> Copied ChineseSimplified.isl to $targetLanguagesDir"

Push-Location $projectRoot
try {
    $maxAttempts = 2
    $attempt = 0
    $exitCode = 0
    do {
        $attempt++
        Write-Host "==> dart run inno_bundle (attempt $attempt/$maxAttempts)"
        dart run inno_bundle
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) { break }
        if ($attempt -lt $maxAttempts) {
            Write-Host "==> inno_bundle failed (exit $exitCode); retrying in 3s..."
            Start-Sleep -Seconds 3
        }
    } while ($attempt -lt $maxAttempts)

    if ($exitCode -ne 0) {
        if ($exitCode -eq 2) {
            Write-Host "==> Hint: exit 2 is usually Inno Setup 'Resource update error (110)'."
            Write-Host "==> Exclude the build folder from antivirus/Windows Defender, then re-run."
        }
        Write-Error "inno_bundle failed with exit code: $exitCode"
        exit $exitCode
    }
}
finally {
    Pop-Location
}

# The installer is written under build\windows\x64\installer\<BuildType> (e.g. Release).
$installerRoot = Join-Path $projectRoot "build\windows\x64\installer"
if (-not (Test-Path -LiteralPath $installerRoot)) {
    Write-Error "Installer directory not found: $installerRoot"
    exit 1
}

$renamed = $false
Get-ChildItem -LiteralPath $installerRoot -Filter "*.exe" -File -Recurse | ForEach-Object {
    $newName = $_.Name -replace [regex]::Escape($versionInfo.Raw), $versionInfo.Display
    if ($newName -ne $_.Name) {
        $newPath = Join-Path $_.DirectoryName $newName
        Move-Item -LiteralPath $_.FullName -Destination $newPath -Force
        Write-Host "==> Renamed: $($_.Name) -> $newName"
        $renamed = $true
    }
}

if (-not $renamed) {
    Write-Host "==> No installer needed renaming"
}
Write-Host "==> Windows packaging completed"
