$logFile = "d:\work\flutter\template\3-38-10\flutter_kts_template\test\full_test_result.log"
"=== 完整路径测试 (管理员权限) ===" | Out-File $logFile
"isAdmin: $((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" | Out-File $logFile -Append
"" | Out-File $logFile -Append

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WT2 {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr CreateFileW(string a, uint b, uint c, IntPtr d, uint e, uint f, IntPtr g);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("winusb.dll", SetLastError=true)] public static extern bool WinUsb_Initialize(IntPtr h, out IntPtr i);
    [DllImport("winusb.dll")] public static extern bool WinUsb_Free(IntPtr i);
}
"@

$vidPid = "VID_0525&PID_A4A1&MI_02"
$ifaceGuid = "de6380a3-b86f-4a19-9948-ecfb26fde307"
$classGuid = "88bae032-5a81-49f0-bc3d-a4ff138216d6"

$tests = @(
    @{ Inst = "6&BABB8EE&0&0002"; Guid = $ifaceGuid; Label = "大写inst+IfaceGUID" }
    @{ Inst = "6&babb8ee&0&0002"; Guid = $ifaceGuid; Label = "小写inst+IfaceGUID" }
    @{ Inst = "6&BABB8EE&0&0002"; Guid = $classGuid; Label = "大写inst+ClassGUID" }
    @{ Inst = "6&babb8ee&0&0002"; Guid = $classGuid; Label = "小写inst+ClassGUID" }
)

foreach ($t in $tests) {
    $path = "\\?\USB#" + $vidPid + "#" + $t.Inst + "#{" + $t.Guid + "}"
    "--- $($t.Label) ---" | Out-File $logFile -Append
    "path: $path" | Out-File $logFile -Append
    $h = [WT2]::CreateFileW($path, 0xC0000000, 3, [IntPtr]::Zero, 3, 0x40000080, [IntPtr]::Zero)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    $hStr = "$h"
    if ($h.ToInt64() -eq -1 -or $h.ToInt64() -eq 0) {
        "  CreateFile FAIL: error=$err handle=$hStr" | Out-File $logFile -Append
    } else {
        "  CreateFile OK: handle=$hStr error=$err" | Out-File $logFile -Append
        $iface = [IntPtr]::Zero
        $ok = [WT2]::WinUsb_Initialize($h, [ref]$iface)
        $err2 = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        "  WinUsb_Initialize: ok=$ok error=$err2 iface=$iface" | Out-File $logFile -Append
        if ($ok) { [WT2]::WinUsb_Free($iface) | Out-Null }
        [WT2]::CloseHandle($h) | Out-Null
    }
    "" | Out-File $logFile -Append
}
"完成" | Out-File $logFile -Append
