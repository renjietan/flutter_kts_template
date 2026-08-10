using System;
using System.Runtime.InteropServices;

class EnumIfaces {
    [DllImport("setupapi.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern IntPtr SetupDiGetClassDevsW(IntPtr ClassGuid, IntPtr Enumerator, IntPtr hwndParent, uint Flags);
    [DllImport("setupapi.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern bool SetupDiEnumDeviceInterfacesW(IntPtr set, IntPtr devInfo, IntPtr ifClassGuid, int idx, ref SP_DEV_IFACE_DATA data);
    [DllImport("setupapi.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern bool SetupDiGetDeviceInterfaceDetailW(IntPtr set, ref SP_DEV_IFACE_DATA data, IntPtr detail, uint size, ref uint req, IntPtr devInfoData);
    [DllImport("setupapi.dll")] static extern bool SetupDiDestroyDeviceInfoList(IntPtr set);

    [StructLayout(LayoutKind.Sequential)]
    struct SP_DEV_IFACE_DATA { public int cbSize; public Guid InterfaceClassGuid; public uint Flags; public IntPtr Reserved; }

    static void Main() {
        // DIGCF_ALLCLASSES | DIGCF_DEVICEINTERFACE = 0x10 | 0x4 = 0x14
        IntPtr set = SetupDiGetClassDevsW(IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, 0x14);
        Console.WriteLine("DeviceInfoSet: " + set);
        int idx = 0;
        int winusbCount = 0;
        while (true) {
            var did = new SP_DEV_IFACE_DATA();
            did.cbSize = Marshal.SizeOf(did);
            bool ok = SetupDiEnumDeviceInterfacesW(set, IntPtr.Zero, IntPtr.Zero, idx, ref did);
            if (!ok) break;

            uint needed = 0;
            SetupDiGetDeviceInterfaceDetailW(set, ref did, IntPtr.Zero, 0, ref needed, IntPtr.Zero);
            if (needed == 0) { idx++; continue; }
            IntPtr buf = Marshal.AllocHGlobal((int)needed);
            // cbSize: 8 on x64, 6 on x86
            Marshal.WriteInt32(buf, IntPtr.Size);
            bool ok2 = SetupDiGetDeviceInterfaceDetailW(set, ref did, buf, needed, ref needed, IntPtr.Zero);
            string path = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + IntPtr.Size));
            Marshal.FreeHGlobal(buf);

            if (path.IndexOf("VID_0525", StringComparison.OrdinalIgnoreCase) >= 0 ||
                path.IndexOf("a4a1", StringComparison.OrdinalIgnoreCase) >= 0) {
                Console.WriteLine("[" + idx + "] GUID=" + did.InterfaceClassGuid);
                Console.WriteLine("     Path=" + path);
                winusbCount++;
            }
            idx++;
        }
        Console.WriteLine("共扫描 " + idx + " 个接口, 匹配 VID_0525 的有 " + winusbCount + " 个");

        // 也列出所有含 WINUSB 或 winusb 的接口
        Console.WriteLine("\n=== 所有含 'usb' 的接口路径 ===");
        idx = 0;
        while (true) {
            var did = new SP_DEV_IFACE_DATA();
            did.cbSize = Marshal.SizeOf(did);
            bool ok = SetupDiEnumDeviceInterfacesW(set, IntPtr.Zero, IntPtr.Zero, idx, ref did);
            if (!ok) break;
            uint needed = 0;
            SetupDiGetDeviceInterfaceDetailW(set, ref did, IntPtr.Zero, 0, ref needed, IntPtr.Zero);
            if (needed == 0) { idx++; continue; }
            IntPtr buf = Marshal.AllocHGlobal((int)needed);
            Marshal.WriteInt32(buf, IntPtr.Size);
            SetupDiGetDeviceInterfaceDetailW(set, ref did, buf, needed, ref needed, IntPtr.Zero);
            string path = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + IntPtr.Size));
            Marshal.FreeHGlobal(buf);
            if (path.IndexOf("usb", StringComparison.OrdinalIgnoreCase) >= 0 && path.StartsWith("\\\\?\\")) {
                Console.WriteLine("  " + path);
            }
            idx++;
        }
        SetupDiDestroyDeviceInfoList(set);
    }
}
