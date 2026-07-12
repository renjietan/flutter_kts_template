// lib/express.dart
import 'dart:io';

import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/core/router/router.dart';
import 'package:flutter_kts_template/core/rtc/managers/udp/udp.manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../logger/logger.dart';
import 'middleware/corsMiddleware.dart';
import 'middleware/errorMiddleware.dart';
import 'middleware/loggerMiddleware.dart';
import 'middleware/parseJsonMiddleware.dart';

class Express {
  static late HttpServer _sev;

  static Future<void> start() async {
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
    _sev = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      int.parse(AppConfig.serverConfig.port),
    );
    final manager = UdpManager();
    await manager.connect("0.0.0.0:3344");
    GlobalLogger.logInfo("Server start :${AppConfig.serverConfig.port}");
  }

  static Future<void> stop() async {
    await _sev.close();
  }
}
