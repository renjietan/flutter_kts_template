$logFile = "d:\work\flutter\template\3-38-10\flutter_kts_template\test\fix_guid_result.log"
"=== 修复 DeviceInterfaceGUIDs 格式 ===" | Out-File $logFile

# 用 .NET 的 API 写入正确的 REG_MULTI_SZ（自动双 null 终止）
$rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
    "SYSTEM\CurrentControlSet\Enum\USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002",
    $true  # writable
)
if ($rk -eq $null) {
    "打开注册表失败(需要管理员权限)" | Out-File $logFile -Append
    return
}

# 写入正确的 REG_MULTI_SZ
$guids = @("{DE6380A3-B86F-4A19-9948-ECFB26FDE307}")
$rk.SetValue("DeviceInterfaceGUIDs", $guids, [Microsoft.Win32.RegistryValueKind]::MultiString)
$rk.Close()
"已写入正确的 REG_MULTI_SZ (双null终止)" | Out-File $logFile -Append

# 验证写入结果
$rk2 = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Enum\USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002")
$val = $rk2.GetValue("DeviceInterfaceGUIDs")
$kind = $rk2.GetValueKind("DeviceInterfaceGUIDs")
$rk2.Close()
"验证: kind=$kind value=$val" | Out-File $logFile -Append

# 用 P/Invoke 验证原始字节
Add-Type -TypeDefinition @"
using System;using System.Runtime.InteropServices;
public class RegChk {
    [DllImport("advapi32.dll", CharSet=CharSet.Unicode)]
    public static extern uint RegOpenKeyEx(IntPtr hKey, string subKey, uint o, int sam, out IntPtr h);
    [DllImport("advapi32.dll", CharSet=CharSet.Unicode)]
    public static extern uint RegQueryValueEx(IntPtr h, string n, IntPtr r, out int t, byte[] d, ref int s);
    [DllImport("advapi32.dll")] public static extern uint RegCloseKey(IntPtr h);
}
"@
$HKLM = [IntPtr]::new(-2147483646)
$hKey = [IntPtr]::Zero
[RegChk]::RegOpenKeyEx($HKLM, "SYSTEM\CurrentControlSet\Enum\USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002", 0, 0x20019, [ref]$hKey) | Out-Null
$t = 0; $s = 0
[RegChk]::RegQueryValueEx($hKey, "DeviceInterfaceGUIDs", [IntPtr]::Zero, [ref]$t, $null, [ref]$s) | Out-Null
$data = New-Object byte[] $s
[RegChk]::RegQueryValueEx($hKey, "DeviceInterfaceGUIDs", [IntPtr]::Zero, [ref]$t, $data, [ref]$s) | Out-Null
[RegChk]::RegCloseKey($hKey) | Out-Null
$hex = ($data | ForEach-Object { $_.ToString("X2") }) -join " "
"修复后字节大小: $s (应该=80)" | Out-File $logFile -Append
"修复后字节: $hex" | Out-File $logFile -Append

# 重启设备
"" | Out-File $logFile -Append
"=== 重启设备 ===" | Out-File $logFile -Append
$r = & pnputil /restart-device "USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002" 2>&1
$r | Out-File $logFile -Append
Start-Sleep -Seconds 3

# 测试路径
"" | Out-File $logFile -Append
"=== 测试路径 ===" | Out-File $logFile -Append
Add-Type -TypeDefinition @"
using System;using System.Runtime.InteropServices;
public class WT4 {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr CreateFileW(string a, uint b, uint c, IntPtr d, uint e, uint f, IntPtr g);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("winusb.dll", SetLastError=true)] public static extern bool WinUsb_Initialize(IntPtr h, out IntPtr i);
    [DllImport("winusb.dll")] public static extern bool WinUsb_Free(IntPtr i);
}
"@
$path = "\\?\USB#VID_0525&PID_A4A1&MI_02#6&BABB8EE&0&0002#{de6380a3-b86f-4a19-9948-ecfb26fde307}"
"路径: $path" | Out-File $logFile -Append
$h = [WT4]::CreateFileW($path, 0xC0000000, 3, [IntPtr]::Zero, 3, 0x40000080, [IntPtr]::Zero)
$err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
$hv = $h.ToInt64()
if ($hv -eq -1 -or $hv -eq 0) {
    "  CreateFile FAIL: error=$err" | Out-File $logFile -Append
} else {
    "  CreateFile OK: handle=$hv" | Out-File $logFile -Append
    $iface = [IntPtr]::Zero
    $ok = [WT4]::WinUsb_Initialize($h, [ref]$iface)
    $err2 = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "  WinUsb_Initialize: ok=$ok error=$err2" | Out-File $logFile -Append
    if ($ok) { [WT4]::WinUsb_Free($iface) | Out-Null }
    [WT4]::CloseHandle($h) | Out-Null
}
"完成" | Out-File $logFile -Append
