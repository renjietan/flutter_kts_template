$ErrorActionPreference = 'Stop'

function Ensure-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return
    }

    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -Wait
    exit
}

function Resolve-ExePaths {
    param(
        [string]$Root
    )

    $paths = @(
        (Join-Path $Root 'build\windows\x64\runner\Debug\CPD.exe'),
        (Join-Path $Root 'build\windows\x64\runner\Release\CPD.exe')
    )
    $resolved = @()
    foreach ($candidate in $paths) {
        if (Test-Path -LiteralPath $candidate) {
            $resolved += (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    if ($resolved.Count -eq 0) {
        throw "未找到 CPD.exe：$($paths -join ' / ')"
    }
    return $resolved
}

Ensure-Admin

$projectRoot = $PSScriptRoot
$exePaths = Resolve-ExePaths -Root $projectRoot

Write-Host "项目根目录: $projectRoot"

foreach ($exePath in $exePaths) {
    $buildType = Split-Path -Leaf (Split-Path -Parent $exePath)
    $ruleName = "CPD-$buildType"
    netsh advfirewall firewall delete rule name="$ruleName" | Out-Null
    Write-Host "恢复 $buildType 程序为 Block(Public): $exePath"
    netsh advfirewall firewall add rule name="$ruleName" dir=in action=block program="$exePath" protocol=UDP profile=Public | Out-Null
    netsh advfirewall firewall add rule name="$ruleName" dir=in action=block program="$exePath" protocol=TCP profile=Public | Out-Null
}

Write-Host "已恢复 Block 防火墙规则。"
