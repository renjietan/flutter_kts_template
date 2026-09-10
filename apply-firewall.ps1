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

function Resolve-DebugExe {
    param(
        [string]$Root
    )

    $preferred = Join-Path $Root 'build\windows\x64\runner\Debug\flutter_kts_template.exe'
    if (Test-Path -LiteralPath $preferred) {
        return (Resolve-Path -LiteralPath $preferred).Path
    }

    $runnerRoot = Join-Path $Root 'build\windows\x64\runner'
    if (Test-Path -LiteralPath $runnerRoot) {
        $candidates = Get-ChildItem -LiteralPath $runnerRoot -Recurse -Filter 'flutter_kts_template.exe' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\Debug\\' } |
            Sort-Object FullName
        if ($candidates.Count -gt 0) {
            return $candidates[0].FullName
        }
    }

    throw "未找到 Debug 程序：$preferred"
}

Ensure-Admin

$projectRoot = $PSScriptRoot
$exePath = Resolve-DebugExe -Root $projectRoot
$ruleName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)

Write-Host "项目根目录: $projectRoot"
Write-Host "Debug 程序: $exePath"
Write-Host "防火墙规则名: $ruleName"

netsh advfirewall firewall delete rule name="$ruleName" protocol=UDP dir=in | Out-Null
netsh advfirewall firewall delete rule name="$ruleName" protocol=TCP dir=in | Out-Null

netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow program="$exePath" protocol=UDP profile=any | Out-Null
netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow program="$exePath" protocol=TCP profile=any | Out-Null

Write-Host "已应用 Allow 防火墙规则。"
