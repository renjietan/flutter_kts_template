using System;
using System.Runtime.InteropServices;

class EnumAll {
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
        using (var sw = new System.IO.StreamWriter("d:\\work\\flutter\\template\\3-38-10\\flutter_kts_template\\test\\enum_all_result.log")) {
            sw.WriteLine("=== 枚举所有设备接口 ===");
            // DIGCF_ALLCLASSES | DIGCF_DEVICEINTERFACE = 0x14
            IntPtr set = SetupDiGetClassDevsW(IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, 0x14);
            sw.WriteLine("DeviceInfoSet: " + set);
            int idx = 0;
            int matchCount = 0;
            while (true) {
                var did = new SP_DEV_IFACE_DATA();
                did.cbSize = Marshal.SizeOf(did);
                bool ok = SetupDiEnumDeviceInterfacesW(set, IntPtr.Zero, IntPtr.Zero, idx, ref did);
                if (!ok) break;

                uint needed = 0;
                SetupDiGetDeviceInterfaceDetailW(set, ref did, IntPtr.Zero, 0, ref needed, IntPtr.Zero);
                if (needed > 0) {
                    IntPtr buf = Marshal.AllocHGlobal((int)needed);
                    Marshal.WriteInt32(buf, IntPtr.Size);
                    bool ok2 = SetupDiGetDeviceInterfaceDetailW(set, ref did, buf, needed, ref needed, IntPtr.Zero);
                    if (ok2) {
                        string path = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + IntPtr.Size));
                        if (path.IndexOf("VID_0525", StringComparison.OrdinalIgnoreCase) >= 0 ||
                            path.IndexOf("a4a1", StringComparison.OrdinalIgnoreCase) >= 0) {
                            sw.WriteLine("[" + idx + "] GUID=" + did.InterfaceClassGuid);
                            sw.WriteLine("     Path=" + path);
                            matchCount++;
                        }
                    }
                    Marshal.FreeHGlobal(buf);
                }
                idx++;
            }
            sw.WriteLine("共扫描 " + idx + " 个接口, 匹配 VID_0525 的有 " + matchCount + " 个");

            // 也列出所有含 USB# 的接口
            sw.WriteLine("");
            sw.WriteLine("=== 所有含 USB# 的接口 ===");
            idx = 0;
            while (true) {
                var did = new SP_DEV_IFACE_DATA();
                did.cbSize = Marshal.SizeOf(did);
                bool ok = SetupDiEnumDeviceInterfacesW(set, IntPtr.Zero, IntPtr.Zero, idx, ref did);
                if (!ok) break;
                uint needed = 0;
                SetupDiGetDeviceInterfaceDetailW(set, ref did, IntPtr.Zero, 0, ref needed, IntPtr.Zero);
                if (needed > 0) {
                    IntPtr buf = Marshal.AllocHGlobal((int)needed);
                    Marshal.WriteInt32(buf, IntPtr.Size);
                    bool ok2 = SetupDiGetDeviceInterfaceDetailW(set, ref did, buf, needed, ref needed, IntPtr.Zero);
                    if (ok2) {
                        string path = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + IntPtr.Size));
                        if (path.IndexOf("USB#", StringComparison.OrdinalIgnoreCase) >= 0) {
                            sw.WriteLine("  " + did.InterfaceClassGuid + " | " + path);
                        }
                    }
                    Marshal.FreeHGlobal(buf);
                }
                idx++;
            }
            SetupDiDestroyDeviceInfoList(set);
            sw.WriteLine("完成");
        }
    }
}
