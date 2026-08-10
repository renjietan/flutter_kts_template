# 重启设备节点并测试符号链接是否出现
$ErrorActionPreference = "Continue"
$logFile = "d:\work\flutter\template\3-38-10\flutter_kts_template\test\restart_result.log"
"=== 1. 重启设备节点 ===" | Out-File $logFile
$r = & pnputil /restart-device "USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002" 2>&1
$r | Out-File $logFile -Append
"" | Out-File $logFile -Append

"=== 2. 等待 3 秒 ===" | Out-File $logFile -Append
Start-Sleep -Seconds 3
"" | Out-File $logFile -Append

Write-Host "=== 3. 测试两种路径 ==="
$paths = @(
    @{ Name = "DeviceInterfaceGUID"; Path = "\\?\USB#VID_0525&PID_A4A1&MI_02#6&BABB8EE&0&0002#{de6380a3-b86f-4a19-9948-ecfb26fde307}" },
    @{ Name = "ClassGUID"; Path = "\\?\USB#VID_0525&PID_A4A1&MI_02#6&BABB8EE&0&0002#{88bae032-5a81-49f0-bc3d-a4ff138216d6}" }
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32Test {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr CreateFileW(string a, uint b, uint c, IntPtr d, uint e, uint f, IntPtr g);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("winusb.dll", SetLastError=true)] public static extern bool WinUsb_Initialize(IntPtr h, out IntPtr i);
    [DllImport("winusb.dll")] public static extern bool WinUsb_Free(IntPtr i);
}
"@

foreach ($p in $paths) {
    "--- $($p.Name) ---" | Out-File $logFile -Append
    "path: $($p.Path)" | Out-File $logFile -Append
    $h = [Win32Test]::CreateFileW($p.Path, 0xC0000000, 3, [IntPtr]::Zero, 3, 0x40000080, [IntPtr]::Zero)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($h -eq [IntPtr]::new(-1) -or $h -eq [IntPtr]::Zero) {
        "  CreateFile FAIL: error=$err" | Out-File $logFile -Append
    } else {
        "  CreateFile OK: handle=$h" | Out-File $logFile -Append
        $iface = [IntPtr]::Zero
        $ok = [Win32Test]::WinUsb_Initialize($h, [ref]$iface)
        $err2 = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        "  WinUsb_Initialize: ok=$ok error=$err2 iface=$iface" | Out-File $logFile -Append
        if ($ok) { [Win32Test]::WinUsb_Free($iface) | Out-Null }
        [Win32Test]::CloseHandle($h) | Out-Null
    }
    "" | Out-File $logFile -Append
}

"=== 4. 枚举 USBDevice 类的设备接口 ===" | Out-File $logFile -Append
Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq 'USBDevice' } | ForEach-Object {
    $ifaceList = (Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName 'DEVPKEY_DeviceInterfaceList' -ErrorAction SilentlyContinue).Data
    "  $($_.InstanceId)" | Out-File $logFile -Append
    "    InterfaceList: $ifaceList" | Out-File $logFile -Append
}
"完成" | Out-File $logFile -Append
