// lib/express.dart
import 'dart:io';

import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/core/router/router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../logger/logger.dart';
import 'middleware/corsMiddleware.dart';
import 'middleware/error_middleware.dart';
import 'middleware/loggerMiddleware.dart';
import 'middleware/parseJsonMiddleware.dart';

class Express {
  static HttpServer? _sev;

  static Future<void> start() async {
    if (_sev != null) return;
    final router = await RouterRegistry.init();
    // 应用中间件管道，包装路由处理器
    final handler = const Pipeline()
        // 注意: 必须放在第一个: 可捕获所有后续代码的异常，包括其他中间件和路由
        .addMiddleware(errorHandler())
        // 读取并解析请求体，存入 context，供后续路由直接使用。
        .addMiddleware(parseJsonMiddleware())
        // 记录 cors 和 parseJsonMiddleware 处理后的请求/响应，并受到 errorHandler 的保护
        .addMiddleware(customLogger())
        // 跨域中间件可以滞后一点，在请求处理前添加 CORS 头，
        .addMiddleware(cors())
        // 注意: 这里必须使用 call 方法 重定向指针
        .addHandler(router.call);
    final preferredPort = int.parse(AppConfig.serverConfig.port);
    final fallbackPort = int.parse(AppConfig.serverConfig.fallbackPort);
    final server = await _bind(
      handler,
      InternetAddress.anyIPv4,
      preferredPort,
      fallbackPort,
    );
    _sev = server;
    AppConfig.actualServerPort = server.port;
    GlobalLogger.logInfo("Server start :${server.port}");
  }

  static Future<HttpServer> _bind(
    Handler handler,
    InternetAddress address,
    int preferredPort,
    int fallbackPort,
  ) async {
    try {
      return await shelf_io.serve(handler, address, preferredPort);
    } on SocketException catch (e) {
      if (!_isAddressInUse(e)) rethrow;
      GlobalLogger.logWarn(
        'Port $preferredPort is already in use '
        '(${e.osError?.message ?? e.message}); '
        'falling back to port $fallbackPort',
      );
      return shelf_io.serve(handler, address, fallbackPort);
    }
  }

  static bool _isAddressInUse(SocketException e) {
    final code = e.osError?.errorCode;
    if (code != null) {
      // EADDRINUSE: 98(Linux/Android), 48(macOS), 10048(Windows WSAEADDRINUSE)
      return code == 98 || code == 48 || code == 10048;
    }
    return e.message.toLowerCase().contains('address already in use');
  }

  static Future<void> stop() async {
    final server = _sev;
    _sev = null;
    AppConfig.actualServerPort = 0;
    if (server != null) {
      await server.close();
    }
  }
}
