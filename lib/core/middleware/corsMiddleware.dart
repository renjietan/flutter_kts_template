
import 'package:shelf/shelf.dart';

Middleware cors() {
  return (Handler innerHandler) {
    return (Request request) async {
      // 处理预检请求（OPTIONS）
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        });
      }
      // 正常请求添加 CORS 头
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
      });
    };
  };
}