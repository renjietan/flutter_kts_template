$logFile = "d:\work\flutter\template\3-38-10\flutter_kts_template\test\install_driver.log"
$inf = "D:\work\flutter\template\3-38-10\USB驱动\usb_driver 07-20\Linux_device_(Interface_2).inf"

"=== 安装公司 INF 驱动 ===" | Out-File $logFile
"INF: $inf" | Out-File $logFile -Append
"" | Out-File $logFile -Append

"=== 1. pnputil /add-driver ===" | Out-File $logFile -Append
$r1 = & pnputil /add-driver $inf /install 2>&1
$r1 | Out-File $logFile -Append
"" | Out-File $logFile -Append

"=== 2. 等待 2 秒 ===" | Out-File $logFile -Append
Start-Sleep -Seconds 2
"" | Out-File $logFile -Append

"=== 3. 检查设备驱动版本 ===" | Out-File $logFile -Append
$id = "USB\VID_0525&PID_A4A1&MI_02\6&BABB8EE&0&0002"
$dv = (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_DriverVersion' -ErrorAction SilentlyContinue).Data
$dd = (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_DriverDesc' -ErrorAction SilentlyContinue).Data
"DriverVersion: $dv" | Out-File $logFile -Append
"DriverDesc: $dd" | Out-File $logFile -Append
"" | Out-File $logFile -Append

"=== 4. 检查 DeviceInterfaceList ===" | Out-File $logFile -Append
$il = (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_DeviceInterfaceList' -ErrorAction SilentlyContinue).Data
"InterfaceList: $il" | Out-File $logFile -Append
"" | Out-File $logFile -Append

"=== 5. 测试路径 ===" | Out-File $logFile -Append
Add-Type -TypeDefinition @"
using System;using System.Runtime.InteropServices;
public class WT3 {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr CreateFileW(string a, uint b, uint c, IntPtr d, uint e, uint f, IntPtr g);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$path = "\\?\USB#VID_0525&PID_A4A1&MI_02#6&BABB8EE&0&0002#{de6380a3-b86f-4a19-9948-ecfb26fde307}"
"测试: $path" | Out-File $logFile -Append
$h = [WT3]::CreateFileW($path, 0xC0000000, 3, [IntPtr]::Zero, 3, 0x40000080, [IntPtr]::Zero)
$err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
$hv = $h.ToInt64()
if ($hv -eq -1 -or $hv -eq 0) {
    "  CreateFile FAIL: error=$err" | Out-File $logFile -Append
} else {
    "  CreateFile OK: handle=$hv error=$err" | Out-File $logFile -Append
    [WT3]::CloseHandle($h) | Out-Null
}
"完成" | Out-File $logFile -Append
