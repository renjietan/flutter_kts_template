import 'dart:io';

import 'package:flutter_kts_template/core/rtc/managers/android-usb/android.usb.manager.dart';
import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_manager.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';

RtcAbstract? _managerSingleton;

/// 按当前平台获取 RTC 通信管理器单例。
///
/// - Android：使用 [AndroidUsbManager]（基于 usb_serial 的 USB 串口通信）
/// - Windows：使用 [WinUsbManager]（基于 WinUSB API 的 WinUSB 设备通信）
/// - macOS / Linux：暂未实现
/// - 其余平台：抛出 [UnsupportedError]
RtcAbstract getUsbManager() {
  if (_managerSingleton != null) return _managerSingleton!;
  if (Platform.isAndroid) {
    _managerSingleton = AndroidUsbManager();
  } else if (Platform.isWindows) {
    _managerSingleton = WinUsbManager();
  } else if (Platform.isMacOS || Platform.isLinux) {
    throw UnsupportedError('桌面端（macOS/Linux）USB 通信尚未实现');
  } else {
    throw UnsupportedError('不支持的平台：${Platform.operatingSystem}');
  }
  return _managerSingleton!;
}
