import 'dart:io';

import 'package:flutter_kts_template/core/utils/common.dart';
import 'package:flutter_kts_template/core/utils/response.dart';
import 'package:flutter_kts_template/core/utils/time.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_essentials/shelf_essentials.dart';
import 'package:path/path.dart' as path;

class UploadController {
  static Future<Response> uploadHandler(Request request) async {
    final form = await request.formData();
    // 获取额外字段
    // final description = form.fields['description'];

    final uploadedFile = form.files['file'];
    if (uploadedFile != null) {
      final bytes = await uploadedFile.readAsBytes();
      String uploadPath = await getUploadsPath();
      String safeFileName = sanitizeFileName(uploadedFile.name);
      String curTime = parseDateTime(DateTime.now());
      curTime = curTime.replaceAll(':', '-');
      // final filePath = '$uploadPath/($curTime) $safeFileName';
      final filePath = path.join(uploadPath, "[$curTime] $safeFileName");
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      GlobalLogger.logInfo(
        "文件名称:$filePath\n; content-type: ${uploadedFile.contentType}",
      );
      return ApiResponse.success(
        message: "上传成功",
        data: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } else {
      return Response.badRequest(body: '上传失败');
    }
  }
}
