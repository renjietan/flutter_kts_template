import 'dart:ffi';
import 'dart:typed_data' show Uint8List;
import 'package:ffi/ffi.dart';

// ============================================================================
// Windows API Constants
// ============================================================================

const int DIGCF_PRESENT = 0x00000002;
const int DIGCF_DEVICEINTERFACE = 0x00000010;
const int DIGCF_ALLCLASSES = 0x00000004;

const int GENERIC_READ = 0x80000000;
const int GENERIC_WRITE = 0x40000000;
const int OPEN_EXISTING = 3;
const int FILE_SHARE_READ = 0x00000001;
const int FILE_SHARE_WRITE = 0x00000002;
const int FILE_ATTRIBUTE_NORMAL = 0x00000080;
const int FILE_FLAG_OVERLAPPED = 0x40000000;
const int INVALID_HANDLE_VALUE = -1;

// USBD_PIPE_TYPE (usb.h): Control=0, Isochronous=1, Bulk=2, Interrupt=3.
const int PIPE_TYPE_CONTROL = 0x00;
const int PIPE_TYPE_ISOCHRONOUS = 0x01;
const int PIPE_TYPE_BULK = 0x02;
const int PIPE_TYPE_INTERRUPT = 0x03;

const int PIPE_ID_IN_MASK = 0x80;

// Pipe policy types (对齐 go.md：仅使用 PIPE_TRANSFER_TIMEOUT)
const int PIPE_TRANSFER_TIMEOUT = 0x03;

// Win32 overlapped I/O / wait constants
const int ERROR_IO_PENDING = 997;
const int INFINITE = 0xFFFFFFFF;
const int WAIT_OBJECT_0 = 0x00000000;
const int WAIT_TIMEOUT = 0x00000102;
const int WAIT_FAILED = 0xFFFFFFFF;

// Registry constants (只读)
const int HKEY_LOCAL_MACHINE = 0x80000002;
const int KEY_READ = 0x20019;

// ============================================================================
// FFI Structs
// ============================================================================

base class GUID extends Struct {
  @Uint32()
  external int data1;

  @Uint16()
  external int data2;

  @Uint16()
  external int data3;

  @Uint32()
  external int data4a;

  @Uint32()
  external int data4b;
}

base class SP_DEVICE_INTERFACE_DATA extends Struct {
  @Uint32()
  external int cbSize;

  external GUID InterfaceClassGuid;

  @Uint32()
  external int Flags;

  @IntPtr()
  external int Reserved;
}

base class SP_DEVINFO_DATA extends Struct {
  @Uint32()
  external int cbSize;

  external GUID DeviceClassGuid;

  @Uint32()
  external int DevInst;

  @IntPtr()
  external int Reserved;
}

base class SP_DEVICE_INTERFACE_DETAIL_DATA_W extends Struct {
  @Uint32()
  external int cbSize;
}

/// USB 接口描述符（WinUsb_QueryInterfaceSettings 实际返回的类型）。
///
/// 对应 `USB_INTERFACE_DESCRIPTOR` (usbspec.h)，共 9 字节。
base class USB_INTERFACE_DESCRIPTOR extends Struct {
  @Uint8()
  external int bLength;

  @Uint8()
  external int bDescriptorType;

  @Uint8()
  external int bInterfaceNumber;

  @Uint8()
  external int bAlternateSetting;

  @Uint8()
  external int bNumEndpoints;

  @Uint8()
  external int bInterfaceClass;

  @Uint8()
  external int bInterfaceSubClass;

  @Uint8()
  external int bInterfaceProtocol;

  @Uint8()
  external int iInterface;
}

/// WinUSB 管道信息（winusbio.h: WINUSB_PIPE_INFORMATION）。
///
/// 布局：PipeType(u32) + PipeId(u8) + [pad 1] + MaximumPacketSize(u16) + Interval(u8)。
base class WINUSB_PIPE_INFORMATION extends Struct {
  @Uint32()
  external int PipeType;

  @Uint8()
  external int PipeId;

  @Uint16()
  external int MaximumPacketSize;

  @Uint8()
  external int Interval;
}

/// Windows OVERLAPPED 结构体（用于 WinUsb_ReadPipe 的异步读）。
///
/// 布局（x64）：ULONG_PTR Internal(8) + ULONG_PTR InternalHigh(8)
/// + union{ DWORD Offset; DWORD OffsetHigh }(8) + HANDLE hEvent(8) = 32 字节。
base class OVERLAPPED extends Struct {
  @UintPtr()
  external int Internal;

  @UintPtr()
  external int InternalHigh;

  @Uint32()
  external int Offset;

  @Uint32()
  external int OffsetHigh;

  @IntPtr()
  external int hEvent;
}

/// Dart 侧的管道信息值对象（从 FFI 结构体拷贝而来，避免 use-after-free）。
class WinUsbPipeInformation {
  final int pipeType;
  final int pipeId;
  final int maximumPacketSize;
  final int interval;

  const WinUsbPipeInformation({
    required this.pipeType,
    required this.pipeId,
    required this.maximumPacketSize,
    required this.interval,
  });
}

/// Dart 侧的接口描述符值对象（从 FFI 结构体拷贝而来，避免 use-after-free）。
class WinUsbInterfaceDescriptor {
  final int interfaceNumber;
  final int alternateSetting;
  final int numEndpoints;
  final int interfaceClass;
  final int interfaceSubClass;
  final int interfaceProtocol;

  const WinUsbInterfaceDescriptor({
    required this.interfaceNumber,
    required this.alternateSetting,
    required this.numEndpoints,
    required this.interfaceClass,
    required this.interfaceSubClass,
    required this.interfaceProtocol,
  });
}

// ============================================================================
// FFI Function Typedefs
// ============================================================================

typedef _SetupDiGetClassDevsW_Native =
    IntPtr Function(
      Pointer<GUID> ClassGuid,
      Pointer<Utf16> Enumerator,
      Pointer Reserved,
      Uint32 Flags,
    );
typedef _SetupDiGetClassDevsW_Dart =
    int Function(
      Pointer<GUID> ClassGuid,
      Pointer<Utf16> Enumerator,
      Pointer Reserved,
      int Flags,
    );

typedef _SetupDiEnumDeviceInterfaces_Native =
    Int32 Function(
      IntPtr DeviceInfoSet,
      Pointer<SP_DEVINFO_DATA> DeviceInfoData,
      Pointer<GUID> InterfaceClassGuid,
      Uint32 MemberIndex,
      Pointer<SP_DEVICE_INTERFACE_DATA> InterfaceData,
    );
typedef _SetupDiEnumDeviceInterfaces_Dart =
    int Function(
      int DeviceInfoSet,
      Pointer<SP_DEVINFO_DATA> DeviceInfoData,
      Pointer<GUID> InterfaceClassGuid,
      int MemberIndex,
      Pointer<SP_DEVICE_INTERFACE_DATA> InterfaceData,
    );

typedef _SetupDiGetDeviceInterfaceDetailW_Native =
    Int32 Function(
      IntPtr DeviceInfoSet,
      Pointer<SP_DEVICE_INTERFACE_DATA> InterfaceData,
      Pointer<SP_DEVICE_INTERFACE_DETAIL_DATA_W> InterfaceDetailData,
      Uint32 InterfaceDetailDataSize,
      Pointer<Uint32> RequiredSize,
      Pointer<SP_DEVINFO_DATA> DeviceInfoData,
    );
typedef _SetupDiGetDeviceInterfaceDetailW_Dart =
    int Function(
      int DeviceInfoSet,
      Pointer<SP_DEVICE_INTERFACE_DATA> InterfaceData,
      Pointer<SP_DEVICE_INTERFACE_DETAIL_DATA_W> InterfaceDetailData,
      int InterfaceDetailDataSize,
      Pointer<Uint32> RequiredSize,
      Pointer<SP_DEVINFO_DATA> DeviceInfoData,
    );

typedef _SetupDiDestroyDeviceInfoList_Native =
    Int32 Function(IntPtr DeviceInfoSet);
typedef _SetupDiDestroyDeviceInfoList_Dart = int Function(int DeviceInfoSet);

typedef _CreateFileW_Native =
    IntPtr Function(
      Pointer<Utf16> lpFileName,
      Uint32 dwDesiredAccess,
      Uint32 dwShareMode,
      Pointer lpSecurityAttributes,
      Uint32 dwCreationDisposition,
      Uint32 dwFlagsAndAttributes,
      IntPtr hTemplateFile,
    );
typedef _CreateFileW_Dart =
    int Function(
      Pointer<Utf16> lpFileName,
      int dwDesiredAccess,
      int dwShareMode,
      Pointer lpSecurityAttributes,
      int dwCreationDisposition,
      int dwFlagsAndAttributes,
      int hTemplateFile,
    );

typedef _CloseHandle_Native = Int32 Function(IntPtr hObject);
typedef _CloseHandle_Dart = int Function(int hObject);

typedef _GetLastError_Native = Uint32 Function();
typedef _GetLastError_Dart = int Function();

typedef _WinUsb_Initialize_Native =
    Int32 Function(IntPtr DeviceHandle, Pointer<IntPtr> InterfaceHandle);
typedef _WinUsb_Initialize_Dart =
    int Function(int DeviceHandle, Pointer<IntPtr> InterfaceHandle);

typedef _WinUsb_Free_Native = Int32 Function(IntPtr InterfaceHandle);
typedef _WinUsb_Free_Dart = int Function(int InterfaceHandle);

typedef _WinUsb_QueryInterfaceSettings_Native =
    Int32 Function(
      IntPtr InterfaceHandle,
      Uint8 AlternateInterfaceNumber,
      Pointer<USB_INTERFACE_DESCRIPTOR> InterfaceDescriptor,
    );
typedef _WinUsb_QueryInterfaceSettings_Dart =
    int Function(
      int InterfaceHandle,
      int AlternateInterfaceNumber,
      Pointer<USB_INTERFACE_DESCRIPTOR> InterfaceDescriptor,
    );

typedef _WinUsb_QueryPipe_Native =
    Int32 Function(
      IntPtr InterfaceHandle,
      Uint8 AlternateInterfaceNumber,
      Uint8 PipeIndex,
      Pointer<WINUSB_PIPE_INFORMATION> PipeInformation,
    );
typedef _WinUsb_QueryPipe_Dart =
    int Function(
      int InterfaceHandle,
      int AlternateInterfaceNumber,
      int PipeIndex,
      Pointer<WINUSB_PIPE_INFORMATION> PipeInformation,
    );

typedef _WinUsb_WritePipe_Native =
    Int32 Function(
      IntPtr InterfaceHandle,
      Uint8 PipeId,
      Pointer<Uint8> Buffer,
      IntPtr BufferLength,
      Pointer<Uint32> LengthTransferred,
      Pointer Overlapped,
    );
typedef _WinUsb_WritePipe_Dart =
    int Function(
      int InterfaceHandle,
      int PipeId,
      Pointer<Uint8> Buffer,
      int BufferLength,
      Pointer<Uint32> LengthTransferred,
      Pointer Overlapped,
    );

typedef _WinUsb_ReadPipe_Native =
    Int32 Function(
      IntPtr InterfaceHandle,
      Uint8 PipeId,
      Pointer<Uint8> Buffer,
      IntPtr BufferLength,
      Pointer<Uint32> LengthTransferred,
      Pointer Overlapped,
    );
typedef _WinUsb_ReadPipe_Dart =
    int Function(
      int InterfaceHandle,
      int PipeId,
      Pointer<Uint8> Buffer,
      int BufferLength,
      Pointer<Uint32> LengthTransferred,
      Pointer Overlapped,
    );

typedef _WinUsb_SetPipePolicy_Native =
    Int32 Function(
      IntPtr InterfaceHandle,
      Uint8 PipeId,
      Uint32 PolicyType,
      Uint32 ValueLength,
      Pointer<Uint32> Value,
    );
typedef _WinUsb_SetPipePolicy_Dart =
    int Function(
      int InterfaceHandle,
      int PipeId,
      int PolicyType,
      int ValueLength,
      Pointer<Uint32> Value,
    );

// WinUsb_FlushPipe - 刷新管道（对齐 go.md 的 Flush）
typedef _WinUsb_FlushPipe_Native =
    Int32 Function(IntPtr InterfaceHandle, Uint8 PipeID);
typedef _WinUsb_FlushPipe_Dart = int Function(int InterfaceHandle, int PipeID);

typedef _WinUsb_AbortPipe_Native =
    Int32 Function(IntPtr InterfaceHandle, Uint8 PipeID);
typedef _WinUsb_AbortPipe_Dart = int Function(int InterfaceHandle, int PipeID);

typedef _WinUsb_GetOverlappedResult_Native =
    Int32 Function(
      IntPtr InterfaceHandle,
      Pointer<OVERLAPPED> Overlapped,
      Pointer<Uint32> BytesTransferred,
      Int32 Wait,
    );
typedef _WinUsb_GetOverlappedResult_Dart =
    int Function(
      int InterfaceHandle,
      Pointer<OVERLAPPED> Overlapped,
      Pointer<Uint32> BytesTransferred,
      int Wait,
    );

typedef _CreateEventW_Native =
    IntPtr Function(
      Pointer EventAttributes,
      Int32 ManualReset,
      Int32 InitialState,
      Pointer<Utf16> Name,
    );
typedef _CreateEventW_Dart =
    int Function(
      Pointer EventAttributes,
      int ManualReset,
      int InitialState,
      Pointer<Utf16> Name,
    );

typedef _ResetEvent_Native = Int32 Function(IntPtr Event);
typedef _ResetEvent_Dart = int Function(int Event);

typedef _SetEvent_Native = Int32 Function(IntPtr Event);
typedef _SetEvent_Dart = int Function(int Event);

typedef _WaitForMultipleObjects_Native =
    Uint32 Function(
      Uint32 Count,
      Pointer<IntPtr> Handles,
      Int32 WaitAll,
      Uint32 Milliseconds,
    );
typedef _WaitForMultipleObjects_Dart =
    int Function(
      int Count,
      Pointer<IntPtr> Handles,
      int WaitAll,
      int Milliseconds,
    );

// ============================================================================
// Registry API FFI bindings (advapi32.dll) - 只读
// ----------------------------------------------------------------------------
// DeviceInterfaceGUIDs 由设备 INF 的 AddDeviceInterfaceGUID 在设备插入时
// 自动写入注册表（见 Linux_device_(Interface_2).inf 的 [AddDeviceInterfaceGUID] 段），
// 因此这里只读取、不自行写入。
// ============================================================================
typedef _RegOpenKeyExW_Native =
    Int32 Function(
      IntPtr hKey,
      Pointer<Utf16> lpSubKey,
      Uint32 ulOptions,
      Uint32 samDesired,
      Pointer<IntPtr> phkResult,
    );
typedef _RegOpenKeyExW_Dart =
    int Function(
      int hKey,
      Pointer<Utf16> lpSubKey,
      int ulOptions,
      int samDesired,
      Pointer<IntPtr> phkResult,
    );

typedef _RegQueryValueExW_Native =
    Int32 Function(
      IntPtr hKey,
      Pointer<Utf16> lpValueName,
      Pointer<Uint32> lpReserved,
      Pointer<Uint32> lpType,
      Pointer<Uint8> lpData,
      Pointer<Uint32> lpcbData,
    );
typedef _RegQueryValueExW_Dart =
    int Function(
      int hKey,
      Pointer<Utf16> lpValueName,
      Pointer<Uint32> lpReserved,
      Pointer<Uint32> lpType,
      Pointer<Uint8> lpData,
      Pointer<Uint32> lpcbData,
    );

typedef _RegCloseKey_Native = Int32 Function(IntPtr hKey);
typedef _RegCloseKey_Dart = int Function(int hKey);

typedef _RegEnumKeyExW_Native =
    Int32 Function(
      IntPtr hKey,
      Uint32 dwIndex,
      Pointer<Utf16> lpName,
      Pointer<Uint32> lpcchName,
      Pointer<Uint32> lpReserved,
      Pointer<Utf16> lpClass,
      Pointer<Uint32> lpcchClass,
      Pointer<Uint32> lpftLastWriteTime,
    );
typedef _RegEnumKeyExW_Dart =
    int Function(
      int hKey,
      int dwIndex,
      Pointer<Utf16> lpName,
      Pointer<Uint32> lpcchName,
      Pointer<Uint32> lpReserved,
      Pointer<Utf16> lpClass,
      Pointer<Uint32> lpcchClass,
      Pointer<Uint32> lpftLastWriteTime,
    );

// ============================================================================
// FFI Function Lookups
// ============================================================================

final _setupapi = DynamicLibrary.open('setupapi.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');
final _winusb = DynamicLibrary.open('winusb.dll');
final _advapi32 = DynamicLibrary.open('advapi32.dll');

final fSetupDiGetClassDevsW = _setupapi
    .lookupFunction<_SetupDiGetClassDevsW_Native, _SetupDiGetClassDevsW_Dart>(
      'SetupDiGetClassDevsW',
    );
final fSetupDiEnumDeviceInterfaces = _setupapi
    .lookupFunction<
      _SetupDiEnumDeviceInterfaces_Native,
      _SetupDiEnumDeviceInterfaces_Dart
    >('SetupDiEnumDeviceInterfaces');
final fSetupDiGetDeviceInterfaceDetailW = _setupapi
    .lookupFunction<
      _SetupDiGetDeviceInterfaceDetailW_Native,
      _SetupDiGetDeviceInterfaceDetailW_Dart
    >('SetupDiGetDeviceInterfaceDetailW');
final fSetupDiDestroyDeviceInfoList = _setupapi
    .lookupFunction<
      _SetupDiDestroyDeviceInfoList_Native,
      _SetupDiDestroyDeviceInfoList_Dart
    >('SetupDiDestroyDeviceInfoList');

final fCreateFileW = _kernel32
    .lookupFunction<_CreateFileW_Native, _CreateFileW_Dart>('CreateFileW');
final fCloseHandle = _kernel32
    .lookupFunction<_CloseHandle_Native, _CloseHandle_Dart>('CloseHandle');
final fGetLastError = _kernel32
    .lookupFunction<_GetLastError_Native, _GetLastError_Dart>('GetLastError');

final fWinUsbInitialize = _winusb
    .lookupFunction<_WinUsb_Initialize_Native, _WinUsb_Initialize_Dart>(
      'WinUsb_Initialize',
    );
final fWinUsbFree = _winusb
    .lookupFunction<_WinUsb_Free_Native, _WinUsb_Free_Dart>('WinUsb_Free');
final fWinUsbQueryInterfaceSettings = _winusb
    .lookupFunction<
      _WinUsb_QueryInterfaceSettings_Native,
      _WinUsb_QueryInterfaceSettings_Dart
    >('WinUsb_QueryInterfaceSettings');
final fWinUsbQueryPipe = _winusb
    .lookupFunction<_WinUsb_QueryPipe_Native, _WinUsb_QueryPipe_Dart>(
      'WinUsb_QueryPipe',
    );
final fWinUsbWritePipe = _winusb
    .lookupFunction<_WinUsb_WritePipe_Native, _WinUsb_WritePipe_Dart>(
      'WinUsb_WritePipe',
    );
final fWinUsbReadPipe = _winusb
    .lookupFunction<_WinUsb_ReadPipe_Native, _WinUsb_ReadPipe_Dart>(
      'WinUsb_ReadPipe',
    );
final fWinUsbSetPipePolicy = _winusb
    .lookupFunction<_WinUsb_SetPipePolicy_Native, _WinUsb_SetPipePolicy_Dart>(
      'WinUsb_SetPipePolicy',
    );
final fWinUsbFlushPipe = _winusb
    .lookupFunction<_WinUsb_FlushPipe_Native, _WinUsb_FlushPipe_Dart>(
      'WinUsb_FlushPipe',
    );
final fWinUsbAbortPipe = _winusb
    .lookupFunction<_WinUsb_AbortPipe_Native, _WinUsb_AbortPipe_Dart>(
      'WinUsb_AbortPipe',
    );
final fWinUsbGetOverlappedResult = _winusb
    .lookupFunction<
      _WinUsb_GetOverlappedResult_Native,
      _WinUsb_GetOverlappedResult_Dart
    >('WinUsb_GetOverlappedResult');

final fCreateEventW = _kernel32
    .lookupFunction<_CreateEventW_Native, _CreateEventW_Dart>('CreateEventW');
final fResetEvent = _kernel32
    .lookupFunction<_ResetEvent_Native, _ResetEvent_Dart>('ResetEvent');
final fSetEvent = _kernel32
    .lookupFunction<_SetEvent_Native, _SetEvent_Dart>('SetEvent');
final fWaitForMultipleObjects = _kernel32
    .lookupFunction<
      _WaitForMultipleObjects_Native,
      _WaitForMultipleObjects_Dart
    >('WaitForMultipleObjects');

final fRegOpenKeyExW = _advapi32
    .lookupFunction<_RegOpenKeyExW_Native, _RegOpenKeyExW_Dart>(
      'RegOpenKeyExW',
    );
final fRegQueryValueExW = _advapi32
    .lookupFunction<_RegQueryValueExW_Native, _RegQueryValueExW_Dart>(
      'RegQueryValueExW',
    );
final fRegCloseKey = _advapi32
    .lookupFunction<_RegCloseKey_Native, _RegCloseKey_Dart>('RegCloseKey');
final fRegEnumKeyExW = _advapi32
    .lookupFunction<_RegEnumKeyExW_Native, _RegEnumKeyExW_Dart>(
      'RegEnumKeyExW',
    );

// ============================================================================
// WinUSB Pipe ID helpers
// ============================================================================

bool isInPipe(int pipeId) => (pipeId & PIPE_ID_IN_MASK) != 0;
bool isOutPipe(int pipeId) => (pipeId & PIPE_ID_IN_MASK) == 0;

/// 携带 Win32 错误码的 WinUSB 调用异常。
class WinUsbError implements Exception {
  final int errorCode;
  final String message;

  WinUsbError(this.errorCode, this.message);

  @override
  String toString() => 'WinUsbError($errorCode): $message';
}

/// 判断错误码是否为「设备已拔出」。
///
/// 拔掉设备后，WinUsb_ReadPipe / WinUsb_WritePipe 通常会返回这些错误码；
/// 正常「无数据超时」通常为 ERROR_SEM_TIMEOUT(121)，不属于设备拔出。
bool isUsbDeviceGoneError(int errorCode) {
  switch (errorCode) {
    case 1167: // ERROR_DEVICE_NOT_CONNECTED
    case 433: // ERROR_NO_SUCH_DEVICE
    case 31: // ERROR_GEN_FAILURE
    case 995: // ERROR_OPERATION_ABORTED
    case 6: // ERROR_INVALID_HANDLE
      return true;
    default:
      return false;
  }
}

// ============================================================================
// Device info model
// ============================================================================

/// Represents a discovered WinUSB device (对齐 go.md 的 DeviceInfo)
class WinUsbDeviceInfo {
  final String devicePath;
  final String instanceId;
  final int vid;
  final int pid;
  final int interfaceNumber;

  const WinUsbDeviceInfo({
    required this.devicePath,
    required this.instanceId,
    required this.vid,
    required this.pid,
    required this.interfaceNumber,
  });

  @override
  String toString() =>
      'WinUsbDeviceInfo(vid: ${vid.toRadixString(16).padLeft(4, '0')}, '
      'pid: ${pid.toRadixString(16).padLeft(4, '0')}, '
      'if: $interfaceNumber, path: $devicePath)';
}

// ============================================================================
// Registry-based device enumeration (对齐 go.md 的 ListDevices)
// ----------------------------------------------------------------------------
// 原理：直接读取 HKLM\SYSTEM\CurrentControlSet\Enum\USB 下的设备列表，
// 找到 Service=WINUSB 的设备，读取其 DeviceInterfaceGUIDs（INF 的
// AddDeviceInterfaceGUID 写入）并构造设备路径，最后用 canOpenAsWinUsb 验证。
// go.md 使用 ClassGUID 构造路径，但根据 INF，正确的接口 GUID 应是
// DeviceInterfaceGUIDs。这里优先读 DeviceInterfaceGUIDs，为空时回退 ClassGUID
// （兼容 go.md 的成功场景）。
// ============================================================================

/// 从注册表枚举所有可用的 WinUSB 设备（Golang 风格，纯读取）。
Future<List<WinUsbDeviceInfo>> listWinUsbDevicesFromRegistry() async {
  final devices = <WinUsbDeviceInfo>[];

  const usbKeyPath = r'SYSTEM\CurrentControlSet\Enum\USB';
  final usbKey = _openRegKey(usbKeyPath);
  if (usbKey == 0) return devices;

  try {
    // 遍历 VID_xxxx&PID_xxxx[&MI_xx] 子键
    final vidPidKeys = _enumRegSubKeys(usbKey);

    for (final vidPidKeyName in vidPidKeys) {
      final vidPidKey = _openRegKey('$usbKeyPath\\$vidPidKeyName');
      if (vidPidKey == 0) continue;

      try {
        // 遍历 Instance ID 子键 (e.g., 6&BABB8EE&0&0002)
        final instanceIds = _enumRegSubKeys(vidPidKey);

        for (final instanceId in instanceIds) {
          final devKeyPath = '$usbKeyPath\\$vidPidKeyName\\$instanceId';
          final devKey = _openRegKey(devKeyPath);
          if (devKey == 0) continue;

          try {
            // 只取 Service=WINUSB 的设备（对齐 go.md）
            final service = _readRegString(devKey, 'Service');
            if (service == null ||
                service.toUpperCase() != 'WINUSB') {
              continue;
            }

            // 优先读 DeviceInterfaceGUIDs（INF 的 AddDeviceInterfaceGUID 写入，
            // 这是 winusb.sys 创建符号链接使用的接口 GUID）。
            // 为空时回退 ClassGUID（go.md 的做法）。
            var guid = _readRegString(devKey, 'DeviceInterfaceGUIDs');
            guid ??= _readRegString(devKey, 'ClassGUID');
            if (guid == null || guid.isEmpty) continue;

            // 去掉 { } 括号（对齐 go.md 的 strings.Trim）
            final cleanedGuid =
                guid.replaceAll('{', '').replaceAll('}', '').trim();

            // 构造设备路径: \\?\USB#VID_xxxx&PID_xxxx&MI_xx#instanceID#{GUID}
            final path =
                r'\\?\USB#' +
                vidPidKeyName +
                '#' +
                instanceId +
                '#{' +
                cleanedGuid +
                '}';

            // 对齐 go.md 的 canOpenAsWinUSB：验证路径能否被 WinUSB 打开
            if (!canOpenAsWinUsb(path)) {
              continue;
            }

            // 解析路径获取 VID, PID, 接口号
            final parsed = _parseDevicePath(path);
            final (vid, pid, interfaceNumber) = parsed ??
                (
                  _extractField(vidPidKeyName, 'VID_'),
                  _extractField(vidPidKeyName, 'PID_'),
                  _extractInterfaceNumber(vidPidKeyName),
                );

            devices.add(
              WinUsbDeviceInfo(
                devicePath: path,
                instanceId: '$vidPidKeyName\\$instanceId',
                vid: vid,
                pid: pid,
                interfaceNumber: interfaceNumber,
              ),
            );
          } finally {
            fRegCloseKey(devKey);
          }
        }
      } finally {
        fRegCloseKey(vidPidKey);
      }
    }
  } finally {
    fRegCloseKey(usbKey);
  }

  return devices;
}

/// SetupDi 枚举兜底（当注册表枚举无结果时使用）。
///
/// 通过 GUID_DEVINTERFACE_USB_DEVICE 枚举当前在线的 USB 设备接口，
/// 过滤出可被 WinUSB 打开的设备路径。
Future<List<WinUsbDeviceInfo>> enumerateWinUsbDevices() async {
  final results = <WinUsbDeviceInfo>[];

  final guidPtr = _allocGuidDevInterfaceUsbDevice();
  try {
    final devInfoSet = fSetupDiGetClassDevsW(
      guidPtr,
      nullptr,
      nullptr,
      DIGCF_PRESENT | DIGCF_DEVICEINTERFACE,
    );

    if (devInfoSet == INVALID_HANDLE_VALUE || devInfoSet == 0) return results;

    try {
      var index = 0;
      while (true) {
        final ifaceData = calloc<SP_DEVICE_INTERFACE_DATA>();
        ifaceData.ref.cbSize = sizeOf<SP_DEVICE_INTERFACE_DATA>();

        final result = fSetupDiEnumDeviceInterfaces(
          devInfoSet,
          nullptr,
          guidPtr,
          index,
          ifaceData,
        );

        if (result == 0) {
          final error = fGetLastError();
          calloc.free(ifaceData);
          // ERROR_NO_MORE_ITEMS (259) or error=0 表示枚举结束
          if (error == 259 || error == 0) break;
          index++;
          continue;
        }

        try {
          final path = _getInterfaceDetailPath(devInfoSet, ifaceData);
          if (path != null) {
            final info = _parseDevicePath(path);
            if (info != null) {
              final (vid, pid, interfaceNumber) = info;
              results.add(
                WinUsbDeviceInfo(
                  devicePath: path,
                  instanceId: '',
                  vid: vid,
                  pid: pid,
                  interfaceNumber: interfaceNumber,
                ),
              );
            }
          }
        } finally {
          calloc.free(ifaceData);
        }
        index++;
      }
    } finally {
      fSetupDiDestroyDeviceInfoList(devInfoSet);
    }
  } finally {
    calloc.free(guidPtr);
  }

  return results;
}

// ============================================================================
// High-level WinUSB helper functions (对齐 go.md)
// ============================================================================

/// 验证路径是否可以被 WinUSB 初始化（对齐 go.md 的 canOpenAsWinUSB）。
///
/// 尝试 CreateFile + WinUsb_Initialize，成功返回 true。
/// 用于在枚举阶段过滤掉无法打开的设备路径。
bool canOpenAsWinUsb(String devicePath) {
  final pathPtr = devicePath.toNativeUtf16();
  int? handle;
  try {
    handle = fCreateFileW(
      pathPtr,
      GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE,
      nullptr,
      OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED,
      0,
    );
    if (handle == INVALID_HANDLE_VALUE || handle == 0) {
      return false;
    }

    final ifaceHandlePtr = calloc<IntPtr>();
    try {
      final result = fWinUsbInitialize(handle, ifaceHandlePtr);
      if (result == 0) {
        return false;
      }
      // 成功，释放接口句柄
      fWinUsbFree(ifaceHandlePtr.value);
      return true;
    } finally {
      calloc.free(ifaceHandlePtr);
    }
  } finally {
    if (handle != null && handle != INVALID_HANDLE_VALUE && handle != 0) {
      fCloseHandle(handle);
    }
    calloc.free(pathPtr);
  }
}

/// 打开设备句柄（对齐 go.md 的 Open: CreateFile + FILE_FLAG_OVERLAPPED）。
int openDevice(String devicePath) {
  final pathPtr = devicePath.toNativeUtf16();
  try {
    final handle = fCreateFileW(
      pathPtr,
      GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE,
      nullptr,
      OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED,
      0,
    );

    if (handle == INVALID_HANDLE_VALUE || handle == 0) {
      final error = fGetLastError();
      throw Exception('CreateFileW failed for $devicePath: error=$error');
    }

    return handle;
  } finally {
    calloc.free(pathPtr);
  }
}

/// 关闭设备句柄。
void closeDevice(int handle) {
  if (handle != 0 && handle != INVALID_HANDLE_VALUE) {
    fCloseHandle(handle);
  }
}

/// 初始化 WinUSB 接口（对齐 go.md 的 WinUsb_Initialize）。
int winUsbInitialize(int deviceHandle) {
  final ifaceHandlePtr = calloc<IntPtr>();

  try {
    final result = fWinUsbInitialize(deviceHandle, ifaceHandlePtr);
    if (result == 0) {
      final error = fGetLastError();
      throw Exception('WinUsb_Initialize failed: error=$error');
    }
    return ifaceHandlePtr.value;
  } finally {
    calloc.free(ifaceHandlePtr);
  }
}

/// 释放 WinUSB 接口句柄（对齐 go.md 的 WinUsb_Free）。
void winUsbFree(int interfaceHandle) {
  if (interfaceHandle != 0) {
    fWinUsbFree(interfaceHandle);
  }
}

/// 查询接口描述符（WinUsb_QueryInterfaceSettings 返回 USB_INTERFACE_DESCRIPTOR）。
WinUsbInterfaceDescriptor queryInterfaceSettings(
  int interfaceHandle,
  int alternateInterfaceNumber,
) {
  final descriptorPtr = calloc<USB_INTERFACE_DESCRIPTOR>();

  try {
    final result = fWinUsbQueryInterfaceSettings(
      interfaceHandle,
      alternateInterfaceNumber,
      descriptorPtr,
    );
    if (result == 0) {
      final error = fGetLastError();
      throw Exception('WinUsb_QueryInterfaceSettings failed: error=$error');
    }
    final descriptor = descriptorPtr.ref;
    return WinUsbInterfaceDescriptor(
      interfaceNumber: descriptor.bInterfaceNumber,
      alternateSetting: descriptor.bAlternateSetting,
      numEndpoints: descriptor.bNumEndpoints,
      interfaceClass: descriptor.bInterfaceClass,
      interfaceSubClass: descriptor.bInterfaceSubClass,
      interfaceProtocol: descriptor.bInterfaceProtocol,
    );
  } finally {
    calloc.free(descriptorPtr);
  }
}

/// 查询单个管道信息（对齐 go.md 的 QueryPipe）。
WinUsbPipeInformation queryPipeInfo(
  int interfaceHandle,
  int interfaceIndex,
  int pipeIndex,
) {
  final pipeInfoPtr = calloc<WINUSB_PIPE_INFORMATION>();

  try {
    final result = fWinUsbQueryPipe(
      interfaceHandle,
      interfaceIndex,
      pipeIndex,
      pipeInfoPtr,
    );
    if (result == 0) {
      final error = fGetLastError();
      throw Exception(
        'WinUsb_QueryPipe failed: index=$pipeIndex, error=$error',
      );
    }
    final pipe = pipeInfoPtr.ref;
    return WinUsbPipeInformation(
      pipeType: pipe.PipeType,
      pipeId: pipe.PipeId,
      maximumPacketSize: pipe.MaximumPacketSize,
      interval: pipe.Interval,
    );
  } finally {
    calloc.free(pipeInfoPtr);
  }
}

/// 列出接口的全部管道（对齐 go.md 的 queryEndpoints 循环 QueryPipe）。
///
/// 返回的管道列表按 PipeId 分类：bit7=1 为 IN 管道，bit7=0 为 OUT 管道。
List<WinUsbPipeInformation> listPipes(
  int interfaceHandle,
  int interfaceIndex,
) {
  final pipes = <WinUsbPipeInformation>[];
  var pipeIndex = 0;

  while (true) {
    try {
      final info = queryPipeInfo(interfaceHandle, interfaceIndex, pipeIndex);
      pipes.add(info);
      pipeIndex++;
    } catch (_) {
      break;
    }
  }

  return pipes;
}

/// 设置管道超时（对齐 go.md 的 setPipeTimeout）。
void setPipeTimeout(int interfaceHandle, int pipeId, int timeoutMs) {
  final valuePtr = calloc<Uint32>();
  valuePtr.value = timeoutMs;

  try {
    final result = fWinUsbSetPipePolicy(
      interfaceHandle,
      pipeId,
      PIPE_TRANSFER_TIMEOUT,
      sizeOf<Uint32>(),
      valuePtr,
    );
    if (result == 0) {
      final error = fGetLastError();
      throw Exception('WinUsb_SetPipePolicy(PIPE_TRANSFER_TIMEOUT) failed: error=$error');
    }
  } finally {
    calloc.free(valuePtr);
  }
}

/// 写数据到 OUT 管道（对齐 go.md 的 Write: WinUsb_WritePipe）。
int winUsbWritePipe(int interfaceHandle, int pipeId, Uint8List data) {
  if (data.isEmpty) return 0;

  final buffer = calloc<Uint8>(data.length);
  final bytesWrittenPtr = calloc<Uint32>();

  try {
    for (var i = 0; i < data.length; i++) {
      buffer[i] = data[i];
    }

    final result = fWinUsbWritePipe(
      interfaceHandle,
      pipeId,
      buffer,
      data.length,
      bytesWrittenPtr,
      nullptr,
    );

    if (result == 0) {
      final error = fGetLastError();
      throw WinUsbError(error, 'WinUsb_WritePipe failed: error=$error');
    }

    return bytesWrittenPtr.value;
  } finally {
    calloc.free(buffer);
    calloc.free(bytesWrittenPtr);
  }
}

/// 从 IN 管道读数据（对齐 go.md 的 Read: WinUsb_ReadPipe）。
Uint8List winUsbReadPipe(int interfaceHandle, int pipeId, int bufferSize) {
  final buffer = calloc<Uint8>(bufferSize);
  final bytesReadPtr = calloc<Uint32>();

  try {
    final result = fWinUsbReadPipe(
      interfaceHandle,
      pipeId,
      buffer,
      bufferSize,
      bytesReadPtr,
      nullptr,
    );

    if (result == 0) {
      final error = fGetLastError();
      throw WinUsbError(error, 'WinUsb_ReadPipe failed: error=$error');
    }

    final bytesRead = bytesReadPtr.value;
    if (bytesRead == 0) {
      return Uint8List(0);
    }

    final data = Uint8List(bytesRead);
    for (var i = 0; i < bytesRead; i++) {
      data[i] = buffer[i];
    }
    return data;
  } finally {
    calloc.free(buffer);
    calloc.free(bytesReadPtr);
  }
}

/// 刷新管道（对齐 go.md 的 Flush: WinUsb_FlushPipe）。
void winUsbFlushPipe(int interfaceHandle, int pipeId) {
  fWinUsbFlushPipe(interfaceHandle, pipeId);
}

/// 中止管道上所有挂起的传输（对齐 WinUSB 的 AbortPipe）。
void winUsbAbortPipe(int interfaceHandle, int pipeId) {
  if (interfaceHandle == 0 || pipeId == 0) return;
  fWinUsbAbortPipe(interfaceHandle, pipeId);
}

// ============================================================================
// Internal helpers
// ============================================================================

/// GUID_DEVINTERFACE_USB_DEVICE = {A5DCBF10-6530-11D2-901F-00C04FB951ED}
Pointer<GUID> _allocGuidDevInterfaceUsbDevice() {
  final p = calloc<GUID>();
  final g = p.ref;
  g.data1 = 0xA5DCBF10;
  g.data2 = 0x6530;
  g.data3 = 0x11D2;
  g.data4a = 0x901F00C0;
  g.data4b = 0x4FB951ED;
  return p;
}

/// 从 `DeviceClasses` 注册表枚举并查找匹配 VID/PID/接口号的设备接口路径。
///
/// WinUSB 设备的接口 GUID 会以子键形式出现在
/// `HKLM\SYSTEM\CurrentControlSet\Control\DeviceClasses` 下，子键值即为
/// 可直接用 `CreateFile` 打开的设备接口路径。
String? findWinUsbDevicePathByDeviceClasses({
  required int vid,
  required int pid,
  int interfaceNumber = 0,
  String? interfaceGuid,
}) {
  const deviceClassesKeyPath =
      r'SYSTEM\CurrentControlSet\Control\DeviceClasses';
  final deviceClassesKey = _openRegKey(deviceClassesKeyPath);
  if (deviceClassesKey == 0) return null;

  final candidates = <String>[];
  try {
    final guidKeys = _enumRegSubKeys(deviceClassesKey);
    for (final guidKeyName in guidKeys) {
      final guidKey = _openRegKey('$deviceClassesKeyPath\\$guidKeyName');
      if (guidKey == 0) continue;
      try {
        final instances = _enumRegSubKeys(guidKey);
        for (final instance in instances) {
          var devicePath = instance;
          // 注册表 DeviceClasses 中的 `##?` 是设备接口符号链接的转义前缀，
          // 实际 `CreateFile` 打开时应使用 `\\?\`，且去掉紧随其后的 `#`。
          if (devicePath.startsWith('##?#')) {
            devicePath = r'\\?\' + devicePath.substring(4);
          }
          if (!devicePath.contains('VID_') || !devicePath.contains('PID_')) {
            continue;
          }
          final parsed = _parseDevicePath(devicePath);
          if (parsed == null) continue;
          final (pathVid, pathPid, pathInterface) = parsed;
          if (pathVid == vid &&
              pathPid == pid &&
              pathInterface == interfaceNumber) {
            if (interfaceGuid != null &&
                !devicePath.contains(interfaceGuid.toLowerCase())) {
              continue;
            }
            candidates.add(devicePath);
          }
        }
      } finally {
        fRegCloseKey(guidKey);
      }
    }
  } finally {
    fRegCloseKey(deviceClassesKey);
  }
  for (final candidate in candidates) {
    if (canOpenAsWinUsb(candidate)) return candidate;
  }
  return candidates.isNotEmpty ? candidates.first : null;
}

/// 打开注册表子键（只读），失败返回 0。
int _openRegKey(String path) {
  final pathPtr = path.toNativeUtf16();
  final hKeyPtr = calloc<IntPtr>();

  final result = fRegOpenKeyExW(
    HKEY_LOCAL_MACHINE,
    pathPtr,
    0,
    KEY_READ,
    hKeyPtr,
  );

  calloc.free(pathPtr);

  if (result != 0) {
    calloc.free(hKeyPtr);
    return 0;
  }

  final hKey = hKeyPtr.value;
  calloc.free(hKeyPtr);
  return hKey;
}

/// 从注册表读取字符串值（支持 REG_SZ / REG_MULTI_SZ，取第一个字符串）。
String? _readRegString(int hKey, String valueName) {
  final valueNamePtr = valueName.toNativeUtf16();
  final dataTypePtr = calloc<Uint32>();
  final dataSizePtr = calloc<Uint32>();

  // 第一次调用获取大小
  fRegQueryValueExW(
    hKey,
    valueNamePtr,
    nullptr,
    dataTypePtr,
    nullptr,
    dataSizePtr,
  );

  final dataSize = dataSizePtr.value;
  String? result;

  if (dataSize > 0) {
    final dataBuffer = calloc<Uint8>(dataSize);
    final queryResult = fRegQueryValueExW(
      hKey,
      valueNamePtr,
      nullptr,
      dataTypePtr,
      dataBuffer,
      dataSizePtr,
    );

    if (queryResult == 0) {
      // REG_MULTI_SZ / REG_SZ: 第一个 \0 之前的内容即为所需字符串
      result = dataBuffer.cast<Utf16>().toDartString();
      if (result.trim().isEmpty) result = null;
    }
    calloc.free(dataBuffer);
  }

  calloc.free(valueNamePtr);
  calloc.free(dataTypePtr);
  calloc.free(dataSizePtr);
  return result;
}

/// 枚举注册表子键名称列表。
List<String> _enumRegSubKeys(int hKey) {
  final names = <String>[];
  var index = 0;

  while (true) {
    final nameBuffer = calloc<Uint16>(256);
    final namePtr = nameBuffer.cast<Utf16>();
    final cchNamePtr = calloc<Uint32>()..value = 256;

    final result = fRegEnumKeyExW(
      hKey,
      index,
      namePtr,
      cchNamePtr,
      nullptr, // lpReserved, must be NULL
      nullptr, // lpClass
      nullptr, // lpcchClass
      nullptr, // lpftLastWriteTime
    );

    if (result == 0) {
      names.add(namePtr.toDartString());
    } else {
      // ERROR_NO_MORE_ITEMS (259) 或其它错误：结束枚举
      calloc.free(nameBuffer);
      calloc.free(cchNamePtr);
      break;
    }
    calloc.free(nameBuffer);
    calloc.free(cchNamePtr);
    index++;
  }

  return names;
}

/// 从 SetupDi 设备接口数据中获取设备路径。
String? _getInterfaceDetailPath(
  int devInfoSet,
  Pointer<SP_DEVICE_INTERFACE_DATA> ifaceData,
) {
  final requiredSizePtr = calloc<Uint32>();

  // 第一次调用获取所需大小
  fSetupDiGetDeviceInterfaceDetailW(
    devInfoSet,
    ifaceData,
    nullptr,
    0,
    requiredSizePtr,
    nullptr,
  );

  final requiredSize = requiredSizePtr.value;
  if (requiredSize == 0) {
    calloc.free(requiredSizePtr);
    return null;
  }

  final detailData = calloc<Uint8>(requiredSize);
  final detailDataStruct =
      detailData.cast<SP_DEVICE_INTERFACE_DETAIL_DATA_W>();
  // SP_DEVICE_INTERFACE_DETAIL_DATA_W.cbSize must be 8 on 64-bit Windows
  detailDataStruct.ref.cbSize = 8;

  final result = fSetupDiGetDeviceInterfaceDetailW(
    devInfoSet,
    ifaceData,
    detailDataStruct,
    requiredSize,
    requiredSizePtr,
    nullptr,
  );

  String? path;
  if (result != 0) {
    final pathPtr = (detailData + 4).cast<Utf16>();
    path = pathPtr.toDartString();
  }

  calloc.free(detailData);
  calloc.free(requiredSizePtr);
  return path;
}

/// 解析设备路径，提取 (vid, pid, interfaceNumber)。
///
/// 路径形如: \\?\USB#VID_0525&PID_A4A1&MI_02#6&BABB8EE&0&0002#{GUID}
(int, int, int)? _parseDevicePath(String path) {
  final normalizedPath = path.replaceAll('/', '\\');

  final regExp = RegExp(
    r'USB#VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})(?:&MI_(\d+))?#',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(normalizedPath);
  if (match == null) return null;

  final vid = int.parse(match.group(1)!, radix: 16);
  final pid = int.parse(match.group(2)!, radix: 16);
  final ifaceStr = match.group(3);
  final interfaceNumber = ifaceStr != null ? int.parse(ifaceStr) : 0;

  return (vid, pid, interfaceNumber);
}

/// 从 VID/PID 键名中提取字段（对齐 go.md 的 extractField）。
int _extractField(String keyName, String prefix) {
  final upper = keyName.toUpperCase();
  final idx = upper.indexOf(prefix);
  if (idx == -1) return 0;
  final start = idx + prefix.length;
  if (start + 4 > keyName.length) return 0;
  return int.tryParse(
        keyName.substring(start, start + 4),
        radix: 16,
      ) ??
      0;
}

/// 从 VID/PID 键名中提取接口号（MI_xx），无则返回 0。
int _extractInterfaceNumber(String keyName) {
  final match = RegExp(
    r'MI_(\d+)',
    caseSensitive: false,
  ).firstMatch(keyName);
  return match != null ? int.parse(match.group(1)!) : 0;
}
