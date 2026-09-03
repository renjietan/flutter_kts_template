import 'dart:io';

import 'android-usb/android.usb.bulk.manager.dart';
import 'keyloader_usb_bulk_manager.dart';
import 'win-usb/win_usb_bulk_manager.dart';

KeyLoaderUsbBulkManager getKeyLoaderUsbBulkManager() {
  if (Platform.isWindows) return WinUsbBulkManager.instance;
  return AndroidUsbBulkManager.instance;
}
