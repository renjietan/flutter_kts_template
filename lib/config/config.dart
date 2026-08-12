import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_kts_template/config/module/database.dart';
import 'package:flutter_kts_template/config/module/server.dart';
import 'package:flutter_kts_template/config/module/udp.dart';

class AppConfig {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'CPD',
  );
  static const String mode = String.fromEnvironment(
    'ENV_MODE',
    defaultValue: 'dev',
  );
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api'; // 根据实际情况修改
    }
    if (Platform.isAndroid) {
      // Android 模拟器使用 10.0.2.2，真机使用电脑的局域网 IP
      return 'http://localhost:8080/api'; // 模拟器
    }
    if (Platform.isIOS) {
      // 真机改为电脑 IP
      return 'http://localhost:8080/api'; // 模拟器
    }
    // 其他平台（Windows/macOS/Linux）直接用 localhost
    return 'http://localhost:8080/api';
  }

  static String zipPassword = "UAE@123";

  static final ServerConfig serverConfig = ServerConfig(
    port: const String.fromEnvironment('SERVER_PORT', defaultValue: "8080"),
  );
  static final DataBaseConfig dataBaseConfig = DataBaseConfig(
    name: const String.fromEnvironment("DB_NAME", defaultValue: "app_db"),
  );
  static final UdpConfig udpConfig = UdpConfig(
    address: const String.fromEnvironment(
      "UDP_ADDRESS",
      defaultValue: "0.0.0.0",
    ),
    port: const String.fromEnvironment("UDP_PORT", defaultValue: "3344"),
    timeoutDuration: Duration(
      seconds: int.parse(
        const String.fromEnvironment("UDP_TIMEOUTDURATION", defaultValue: "3"),
      ),
    ),
  );
}
