import 'dart:io';

import 'package:flutter_kts_template/core/utils/common.dart';
import 'package:flutter_kts_template/core/utils/response.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_essentials/shelf_essentials.dart';

class UploadController {
  static Future<Response> uploadHandler(Request request) async {
    final form = await request.formData();
    // 获取额外字段
    // final description = form.fields['description'];

    final uploadedFile = form.files['file'];
    if (uploadedFile != null) {
      GlobalLogger.logInfo(
        "文件名称:${uploadedFile.name}; content-type: ${uploadedFile.contentType}",
      );
      final bytes = await uploadedFile.readAsBytes();
      String uploadPath = await getUploadsDirectory();

      String safeFileName = uploadedFile.name.replaceAll(RegExp(r'[\\/]'), '_');
      final filePath = '$uploadPath/$safeFileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return ApiResponse.success(
        message: "上传成功",
        data: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } else {
      return Response.badRequest(body: '上传失败');
    }
  }
}
