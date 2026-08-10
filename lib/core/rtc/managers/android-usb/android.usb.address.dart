import 'package:usb_serial/usb_serial.dart';

/// Android USB 设备地址。
///
/// 采用 `vid:pid` 格式标识一个 USB 串口设备，例如 `1027:24577`（FTDI FT232R）。
/// `vid`/`pid` 在设备重新插拔后保持不变，比 `deviceId`（每次插拔都会变化）更稳定，
/// 因此作为 [AndroidUsbManager] 中识别远端设备的依据。
class AndroidUsbAddress {
  final int vid;
  final int pid;

  AndroidUsbAddress(this.vid, this.pid) {
    if (vid < 0 || vid > 0xFFFF) {
      throw ArgumentError.value(vid, 'vid', 'vid 范围应为 0~65535');
    }
    if (pid < 0 || pid > 0xFFFF) {
      throw ArgumentError.value(pid, 'pid', 'pid 范围应为 0~65535');
    }
  }

  /// 由 `vid:pid` 字符串构造。
  ///
  /// vid / pid 可为十进制或 `0x` 开头的十六进制，例如：
  /// - `1027:24577`
  /// - `0x0403:0x6001`
  factory AndroidUsbAddress.fromString(String str) {
    final parts = str.split(':');
    if (parts.length != 2) {
      throw FormatException('USB 地址格式错误，应为 vid:pid，实际: $str');
    }
    final vid = _parseId(parts[0], 'vid');
    final pid = _parseId(parts[1], 'pid');
    return AndroidUsbAddress(vid, pid);
  }

  /// 由 [UsbDevice] 构造地址。
  factory AndroidUsbAddress.fromDevice(UsbDevice device) {
    if (device.vid == null || device.pid == null) {
      throw ArgumentError('UsbDevice 缺少 vid 或 pid，无法生成地址');
    }
    return AndroidUsbAddress(device.vid!, device.pid!);
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
  String toString() => '$vid:$pid';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AndroidUsbAddress && vid == other.vid && pid == other.pid);

  @override
  int get hashCode => vid.hashCode ^ pid.hashCode;
}
