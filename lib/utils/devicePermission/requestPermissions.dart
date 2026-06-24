import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestPermission {
  static Future<bool> requestStoragePermission() async {
    // Web 平台不需要存储权限
    if (kIsWeb ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isIOS ||
        !Platform.isAndroid) {
      return true;
    }
    // Android 11 以下不需要此权限（用 READ/WRITE_EXTERNAL_STORAGE）
    if (Platform.operatingSystemVersion.compareTo('10') <= 0) {
      // 如果 SDK < 30，使用普通存储权限
      return await _requestLegacyStorage();
    }

    var status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      return true; // 已有权限
    }

    if (status.isPermanentlyDenied) {
      // 被永久拒绝，引导用户去设置
      return false;
    }

    // 请求权限（会跳转到系统设置页面，要求用户手动开启）
    status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  /// Android 10 及以下的传统存储权限（可选）
  static Future<bool> _requestLegacyStorage() async {
    var status = await Permission.storage.status;
    if (status.isGranted) return true;

    status = await Permission.storage.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }
}
