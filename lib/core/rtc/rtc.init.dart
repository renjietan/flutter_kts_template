import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';

RtcAbstract? _managerSingleton;

RtcAbstract getHidManager() {
  if (_managerSingleton != null) return _managerSingleton!;
  // if (Platform.isAndroid) {
  //   _hidManagerSingleton = AndroidSerialManager();
  // } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
  //   _hidManagerSingleton = DesktopSerialManager();
  // } else {
  //   throw UnsupportedError('Unsupported platform for serial communication');
  // }
  return _managerSingleton!;
}
