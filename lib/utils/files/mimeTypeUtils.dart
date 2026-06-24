import 'package:mime/mime.dart';

class MimeTypeUtils {
  /// 根据文件扩展名获取 MIME 类型
  static String? getMimeType(String fileName) {
    return lookupMimeType(fileName);
  }

  /// 获取文件扩展名（不含点）
  static String getExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// 判断是否为常见文本类型（可自定）
  static bool isTextFile(String fileName) {
    final ext = getExtension(fileName);
    return ['txt', 'json', 'xml', 'csv', 'html', 'css', 'js'].contains(ext);
  }

  /// 判断是否为压缩文件
  static bool isArchiveFile(String fileName) {
    final ext = getExtension(fileName);
    return ['zip', 'rar', '7z', 'tar', 'gz'].contains(ext);
  }

  // 可按需扩展更多判断方法
}
