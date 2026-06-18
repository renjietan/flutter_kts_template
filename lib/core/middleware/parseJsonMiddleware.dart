import 'dart:convert';

import 'package:flutter_kts_template/core/enum/request.dart';
import 'package:flutter_kts_template/core/utils/response.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:shelf/shelf.dart';

Middleware parseJsonMiddleware() {
  return (Handler handle) {
    return (Request request) async {
      String method = request.method;
      Map<String, dynamic> data = {};
      String contentType = request.headers['Content-Type'] ?? '';
      if (method == "GET") {
        data = request.url.queryParameters;
      } else if (contentType.startsWith(EnumContentType.json.value) == true) {
        try {
          final body = await request.readAsString();
          data = jsonDecode(body);
        } on FormatException catch (e) {
          GlobalLogger.logError('Invalid JSON: ${e.message}');
          return ApiResponse.internalError(
            message: 'Invalid JSON: ${e.message}',
          );
        }
      } else if (contentType.startsWith(EnumContentType.multipart.value) ==
              true &&
          method == "POST") {
        try {
          // // 使用 shelf_essentials 解析 multipart 请求
          // final form = await request.formData();
          //
          // // 提取普通字段 -> params
          // var params = Map<String, dynamic>.from(form.fields);
          // // 将文件信息单独放入 context，key 为 'files'
          // // form.files 是 Map<String, FormDataFile>
          // final files = form.files;
          //
          // request = request.change(
          //   context: {
          //     ...request.context,
          //     'params': params,
          //     'files': files, // 后续 handler 可以通过 request.context['files'] 获取
          //     // 你也可以存放原始的 FormData 对象
          //     'formData': form,
          //   },
          // );
          return handle(request);
        } catch (e, stack) {
          GlobalLogger.logError('Failed to parse multipart request: $e');
          return ApiResponse.internalError(
            message: 'Failed to parse file upload',
          );
        }
      } else {
        return ApiResponse.error(message: "未知的Content-Type");
      }
      // 将解析结果存入 context，并保留原始请求体（如果需要）
      request = request.change(context: {...request.context, 'params': data});
      return handle(request);
    };
  };
}
