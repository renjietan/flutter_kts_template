import 'win_usb_ffi.dart';

/// Windows WinUSB 设备地址。
///
/// 采用 `vid:pid:interface` 格式标识一个 WinUSB 设备的特定接口，
/// 例如 `0x0525:0xA4A1:2`（VID=0525, PID=A4A1, 接口=2）。
/// 对于复合设备（Composite Device），同一 VID/PID 可能对应多个接口（MI_00、MI_01、MI_02 等），
/// 因此需要通过接口编号来精确定位。
class WinUsbAddress {
  final int vid;
  final int pid;
  final int interfaceNumber;

  WinUsbAddress(this.vid, this.pid, [this.interfaceNumber = 0]) {
    if (vid < 0 || vid > 0xFFFF) {
      throw ArgumentError.value(vid, 'vid', 'vid 范围应为 0~65535');
    }
    if (pid < 0 || pid > 0xFFFF) {
      throw ArgumentError.value(pid, 'pid', 'pid 范围应为 0~65535');
    }
    if (interfaceNumber < 0 || interfaceNumber > 255) {
      throw ArgumentError.value(interfaceNumber, 'interfaceNumber', '接口编号范围应为 0~255');
    }
  }

  /// 由 `vid:pid` 或 `vid:pid:interface` 字符串构造。
  ///
  /// vid / pid 可为十进制或 `0x` 开头的十六进制，例如：
  /// - `0x0525:0xA4A1:2`
  /// - `1317:42177:0`
  factory WinUsbAddress.fromString(String str) {
    final parts = str.split(':');
    if (parts.length < 2 || parts.length > 3) {
      throw FormatException('USB 地址格式错误，应为 vid:pid 或 vid:pid:interface，实际: $str');
    }
    final vid = _parseId(parts[0], 'vid');
    final pid = _parseId(parts[1], 'pid');
    final iface = parts.length == 3 ? _parseId(parts[2], 'interface') : 0;
    return WinUsbAddress(vid, pid, iface);
  }

  /// 由 [WinUsbDeviceInfo] 构造地址。
  factory WinUsbAddress.fromDeviceInfo(WinUsbDeviceInfo info) {
    return WinUsbAddress(info.vid, info.pid, info.interfaceNumber);
  }

  static int _parseId(String raw, String name) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw FormatException('$name 不能为空');
    }
    final lower = trimmed.toLowerCase();
    final int? value =
        lower.startsWith('0x')
            ? int.tryParse(trimmed.substring(2), radix: 16)
            : int.tryParse(trimmed, radix: 10);
    if (value == null) {
      throw FormatException('$name 解析失败: $raw');
    }
    return value;
  }

  @override
  String toString() => '$vid:$pid:$interfaceNumber';

  String toHexString() =>
      '0x${vid.toRadixString(16).padLeft(4, '0').toUpperCase()}:'
      '0x${pid.toRadixString(16).padLeft(4, '0').toUpperCase()}:'
      '$interfaceNumber';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WinUsbAddress &&
          vid == other.vid &&
          pid == other.pid &&
          interfaceNumber == other.interfaceNumber);

  @override
  int get hashCode => vid.hashCode ^ pid.hashCode ^ interfaceNumber.hashCode;
}
