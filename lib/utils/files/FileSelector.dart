// file_selector.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:unified_popups/unified_popups.dart';

import '../devicePermission/requestPermissions.dart';

class FileSelector {
  /// 选择单个文件（任意类型）
  static Future<PlatformFile?> pickFile(List<String>? extensions) async {
    // 处理权限
    bool hasPermission = await RequestPermission.requestStoragePermission();
    if (!hasPermission) {
      Pop.toast('存储权限未授予，无法选择文件', toastType: ToastType.warn);
      return null;
    }
    FilePickerResult? result;
    // 打开文件选择器
    result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions ?? ['json', 'zip'],
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.first; // 返回选中的文件
    }
    return null;
  }
}
