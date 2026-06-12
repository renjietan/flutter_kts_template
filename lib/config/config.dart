import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/config/module/database.dart';
import 'package:flutter_kts_template/config/module/server.dart';

class AppConfig {
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'CPD');
  static const String mode = String.fromEnvironment('ENV_MODE', defaultValue: 'prod');
  static final ServerConfig serverConfig = ServerConfig(
      port: const String.fromEnvironment('SERVER_PORT', defaultValue: "8080"),
  );
  static final DataBaseConfig dataBaseConfig = DataBaseConfig(
    name: const String.fromEnvironment("DB_NAME", defaultValue: "app_db"),
  );
}