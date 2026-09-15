$ErrorActionPreference = "Stop"

function Get-VersionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $pubspec = Join-Path $ProjectRoot "pubspec.yaml"
    $raw = $null
    foreach ($line in Get-Content -LiteralPath $pubspec) {
        if ($line -match '^\s*version:\s*(\S+)') {
            $raw = $Matches[1]
            break
        }
    }

    if (-not $raw) {
        Write-Error "version not found in pubspec.yaml"
        exit 1
    }

    $display = $raw -replace [regex]::Escape("+"), "."
    return [pscustomobject]@{
        Raw     = $raw
        Display = $display
    }
}
