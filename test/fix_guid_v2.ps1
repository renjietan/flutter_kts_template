$logFile = "d:\work\flutter\template\3-38-10\flutter_kts_template\test\fix_guid_v2_result.log"
"=== 用 P/Invoke 写入正确的 REG_MULTI_SZ (80字节, 双null) ===" | Out-File $logFile

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class RegFix {
    [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern uint RegOpenKeyEx(IntPtr hKey, string subKey, uint options, int sam, out IntPtr phkResult);
    [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern uint RegSetValueExW(IntPtr hKey, string valueName, uint reserved, int type, byte[] data, int dataSize);
    [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern uint RegQueryValueEx(IntPtr hKey, string valueName, IntPtr reserved, out int type, byte[] data, ref int dataSize);
    [DllImport("advapi32.dll")] public static extern uint RegCloseKey(IntPtr hKey);

    public static string FixAndVerify(string subKey, string valueName, string guid) {
        IntPtr HKLM = new IntPtr(-2147483646);
        IntPtr hKey;
        uint r1 = RegOpenKeyEx(HKLM, subKey, 0, 0x20006, out hKey); // KEY_READ|KEY_WRITE = 0x20019|0x2 = 0x2001B... actually 0x20019|0x2
        if (r1 != 0) return "OpenKey failed: " + r1;

        // 构造正确的 REG_MULTI_SZ: {GUID}\0\0 (双null终止)
        string s = guid + "\0\0"; // 字符串 + null + 列表终止null
        byte[] data = Encoding.Unicode.GetBytes(s);
        // data 现在是 {GUID}\0\0 的 UTF-16 字节, 长度 = (guid.Length+2)*2

        uint r2 = RegSetValueExW(hKey, valueName, 0, 7, data, data.Length); // 7 = REG_MULTI_SZ
        string result = "SetValue: " + r2 + " dataSize=" + data.Length;
        if (r2 != 0) { RegCloseKey(hKey); return result; }

        // 验证
        int type; int size = 0;
        RegQueryValueEx(hKey, valueName, IntPtr.Zero, out type, null, ref size);
        byte[] verify = new byte[size];
        RegQueryValueEx(hKey, valueName, IntPtr.Zero, out type, verify, ref size);
        string hex = BitConverter.ToString(verify);
        result += " | verify size=" + size + " type=" + type + " hex=" + hex;

        RegCloseKey(hKey);
        return result;
    }
}
"@

$subKey = "SYSTEM\CurrentControlSet\Enum\USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002"
$result = [RegFix]::FixAndVerify($subKey, "DeviceInterfaceGUIDs", "{DE6380A3-B86F-4A19-9948-ECFB26FDE307}")
$result | Out-File $logFile -Append
"" | Out-File $logFile -Append

# 重启设备
"=== 重启设备 ===" | Out-File $logFile -Append
$r = & pnputil /restart-device "USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002" 2>&1
$r | Out-File $logFile -Append
Start-Sleep -Seconds 4
"" | Out-File $logFile -Append

# 测试所有路径
"=== 测试路径 ===" | Out-File $logFile -Append
Add-Type -TypeDefinition @"
using System;using System.Runtime.InteropServices;
public class WT5 {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr CreateFileW(string a, uint b, uint c, IntPtr d, uint e, uint f, IntPtr g);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("winusb.dll", SetLastError=true)] public static extern bool WinUsb_Initialize(IntPtr h, out IntPtr i);
    [DllImport("winusb.dll")] public static extern bool WinUsb_Free(IntPtr i);
}
"@
$paths = @(
    "\\?\USB#VID_0525&PID_A4A1&MI_02#6&BABB8EE&0&0002#{de6380a3-b86f-4a19-9948-ecfb26fde307}",
    "\\?\USB#VID_0525&PID_A4A1&MI_02#6&babb8ee&0&0002#{de6380a3-b86f-4a19-9948-ecfb26fde307}",
    "\\?\USB#VID_0525&PID_A4A1&MI_02#6&BABB8EE&0&0002#{F72FE0D4-CBCB-407d-8814-9ED673D0DD6B}"
)
foreach ($p in $paths) {
    "path: $p" | Out-File $logFile -Append
    $h = [WT5]::CreateFileW($p, 0xC0000000, 3, [IntPtr]::Zero, 3, 0x40000080, [IntPtr]::Zero)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    $hv = 0
    try { $hv = $h.ToInt64() } catch {}
    if ($hv -eq -1 -or $hv -eq 0) {
        "  CreateFile FAIL: error=$err" | Out-File $logFile -Append
    } else {
        "  CreateFile OK: handle=$hv error=$err" | Out-File $logFile -Append
        $iface = [IntPtr]::Zero
        $ok = [WT5]::WinUsb_Initialize($h, [ref]$iface)
        $err2 = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        "  WinUsb_Initialize: ok=$ok error=$err2" | Out-File $logFile -Append
        if ($ok) { [WT5]::WinUsb_Free($iface) | Out-Null }
        [WT5]::CloseHandle($h) | Out-Null
    }
    "" | Out-File $logFile -Append
}
"完成" | Out-File $logFile -Append
