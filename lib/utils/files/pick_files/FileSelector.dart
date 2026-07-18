// file_selector.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

import '../../devicePermission/requestPermissions.dart';
import '../exception/PermissionException.dart';

class FileSelector {
  /// 选择单个文件（zip、json）
  static Future<PlatformFile?> pickFile(List<String>? extensions) async {
    // 处理权限
    bool hasPermission = await RequestPermission.requestStoragePermission();
    if (!hasPermission) {
      throw PermissionException(t.permission.no);
    }
    FilePickerResult? result;
    // 打开文件选择器
    result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions ?? ['zip'],
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.first; // 返回选中的文件
    }
    return null;
  }

  /// 选择文件夹
  static Future<String?> pickFolder() async {
    bool hasPermission = await RequestPermission.requestStoragePermission();
    if (!hasPermission) {
      throw PermissionException(t.permission.no);
    }
    String? path = await FilePicker.getDirectoryPath(
      dialogTitle: t.uploads.selectedFolderDialogTitle,
    );
    return path;
  }
}
