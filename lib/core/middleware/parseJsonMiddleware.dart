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
      List<String> path = request.url.pathSegments;
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
      }
      // 将解析结果存入 context，并保留原始请求体（如果需要）
      request = request.change(
        context: {...request.context, 'params': data, "path": path},
      );
      return handle(request);
    };
  };
}
