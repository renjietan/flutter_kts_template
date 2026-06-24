import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_kts_template/config/module/database.dart';
import 'package:flutter_kts_template/config/module/server.dart';

class AppConfig {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'CPD',
  );
  static const String mode = String.fromEnvironment(
    'ENV_MODE',
    defaultValue: 'prod',
  );
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api'; // 根据实际情况修改
    }
    if (Platform.isAndroid) {
      // Android 模拟器使用 10.0.2.2，真机使用电脑的局域网 IP
      return 'http://10.0.2.2:8080/api'; // 模拟器
    }
    if (Platform.isIOS) {
      // 真机改为电脑 IP
      return 'http://localhost:8080/api'; // 模拟器
    }
    // 其他平台（Windows/macOS/Linux）直接用 localhost
    return 'http://localhost:8080/api';
  }

  static final ServerConfig serverConfig = ServerConfig(
    port: const String.fromEnvironment('SERVER_PORT', defaultValue: "8080"),
  );
  static final DataBaseConfig dataBaseConfig = DataBaseConfig(
    name: const String.fromEnvironment("DB_NAME", defaultValue: "app_db"),
  );
}
