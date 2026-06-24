import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/utils/files/mimeTypeUtils.dart';

class UFile {
  final String? path;
  final Uint8List? bytes;
  final String fileName;
  final int? size;

  UFile({this.path, this.bytes, required this.fileName, this.size})
    : assert(path != null || bytes != null, '必须提供 path 或 bytes');

  /// 获取文件数据（File 或 Uint8List）
  Future<File> getFile() async {
    if (path != null) {
      return File(path!);
    } else {
      // 如果是字节数据，先写入临时文件（便于 MultipartFile 构造）
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(bytes!);
      return tempFile;
    }
  }

  /// 获取 MIME 类型
  String? get mimeType => MimeTypeUtils.getMimeType(fileName);
}
