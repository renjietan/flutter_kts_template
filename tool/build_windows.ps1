$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot

$versionScript = Join-Path $PSScriptRoot "version.ps1"
. $versionScript
$versionInfo = Get-VersionInfo -ProjectRoot $projectRoot

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
