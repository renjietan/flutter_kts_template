using System;
using System.Runtime.InteropServices;

class PathTest {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern IntPtr CreateFileW(string lpFileName, uint dwDesiredAccess, uint dwShareMode,
        IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("winusb.dll", SetLastError=true)] static extern bool WinUsb_Initialize(IntPtr h, out IntPtr iface);
    [DllImport("winusb.dll")] static extern bool WinUsb_Free(IntPtr iface);

    const uint GENERIC_READ = 0x80000000;
    const uint GENERIC_WRITE = 0x40000000;
    const uint FILE_SHARE_RW = 0x3;
    const uint OPEN_EXISTING = 3;
    const uint OVERLAPPED = 0x40000000;
    const uint NORMAL = 0x80;
    static readonly IntPtr INVALID = new IntPtr(-1);

    static void Test(System.IO.StreamWriter sw, string label, string path) {
        sw.WriteLine("--- " + label + " ---");
        sw.WriteLine("path: " + path);
        var h = CreateFileW(path, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_RW,
            IntPtr.Zero, OPEN_EXISTING, NORMAL | OVERLAPPED, IntPtr.Zero);
        int err = Marshal.GetLastWin32Error();
        if (h == INVALID || h == IntPtr.Zero) {
            sw.WriteLine("  CreateFile FAIL: error=" + err);
            sw.Flush();
            return;
        }
        sw.WriteLine("  CreateFile OK: handle=" + h + " error=" + err);
        IntPtr iface;
        bool ok = WinUsb_Initialize(h, out iface);
        int err2 = Marshal.GetLastWin32Error();
        sw.WriteLine("  WinUsb_Initialize: ok=" + ok + " error=" + err2 + " iface=" + iface);
        if (ok) WinUsb_Free(iface);
        CloseHandle(h);
        sw.Flush();
    }

    static void Main() {
        using (var sw = new System.IO.StreamWriter("d:\\work\\flutter\\template\\3-38-10\\flutter_kts_template\\test\\path_test_result.log")) {
            sw.WriteLine("isAdmin: " + new System.Security.Principal.WindowsPrincipal(System.Security.Principal.WindowsIdentity.GetCurrent()).IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator));
            string inst = "6&BABB8EE&0&0002";
            string instLower = "6&babb8ee&0&0002";
            string vidPid = "VID_0525&PID_A4A1&MI_02";
            string prefix = "\\\\?\\USB#" + vidPid + "#";

            Test(sw, "ClassGUID + UPPER inst", prefix + inst + "#{88bae032-5a81-49f0-bc3d-a4ff138216d6}");
            Test(sw, "ClassGUID + lower inst", prefix + instLower + "#{88bae032-5a81-49f0-bc3d-a4ff138216d6}");
            Test(sw, "IfaceGUID + UPPER inst", prefix + inst + "#{de6380a3-b86f-4a19-9948-ecfb26fde307}");
            Test(sw, "IfaceGUID + lower inst", prefix + instLower + "#{de6380a3-b86f-4a19-9948-ecfb26fde307}");
        }
    }
}
