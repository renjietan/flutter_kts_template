import 'dart:io';

import 'package:flutter_kts_template/core/utils/common.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/core/utils/response.dart';
import 'package:flutter_kts_template/core/utils/time.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf_essentials/shelf_essentials.dart';

class UploadController {
  static Future<Response> uploadHandler(Request request) async {
    final form = await request.formData();
    // 获取额外字段
    // final description = form.fields['description'];
    final uploadedFile = form.files['file'];
    if (uploadedFile != null) {
      final bytes = await uploadedFile.readAsBytes();
      String uploadPath = await DirectoryManager.instance.getUploadsPath();
      String safeFileName = sanitizeFileName(uploadedFile.name);
      String curTime = parseDateTime(DateTime.now());
      curTime = curTime.replaceAll(':', '-');
      final filePath = path.join(uploadPath, "[$curTime] $safeFileName");
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      GlobalLogger.logDebug(
        "文件存储路径:$filePath; \ncontent-type: ${uploadedFile.contentType}",
      );
      return ApiResponse.success(message: "上传成功", data: filePath);
    } else {
      return Response.badRequest(body: '上传失败');
    }
  }

  static Future<Response> unZipFile(Request request) async {
    final form = await request.formData();
    // 获取额外字段
    // final description = form.fields['description'];

    final uploadedFile = form.files['file'];
    if (uploadedFile != null) {
      final bytes = await uploadedFile.readAsBytes();
      String uploadPath = await DirectoryManager.instance.getUploadsPath();
      String safeFileName = sanitizeFileName(uploadedFile.name);
      String curTime = parseDateTime(DateTime.now());
      curTime = curTime.replaceAll(':', '-');
      final filePath = path.join(uploadPath, "[$curTime] $safeFileName");
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      GlobalLogger.logDebug(
        "文件存储路径:$filePath; \ncontent-type: ${uploadedFile.contentType}",
      );
      return ApiResponse.success(message: t.uploads.success, data: filePath);
    } else {
      return Response.badRequest(body: t.uploads.failed);
    }
  }
}
