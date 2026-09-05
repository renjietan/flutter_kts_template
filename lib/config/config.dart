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

  /// Express（shelf 服务）实际监听的端口。
  /// 启动前为 0；启动后由 Express 回写。若默认端口被占用，
  /// 服务会回退到系统分配的空闲端口，此值即实际端口。
  static int actualServerPort = 0;

  static String get baseUrl {
    final port = actualServerPort > 0
        ? actualServerPort
        : int.parse(serverConfig.port);
    // shelf 服务与应用运行在同一进程内，所有平台都通过 localhost 访问自身服务。
    return 'http://localhost:$port/api';
  }

  static String zipPassword = "UAE@123";

  static final ServerConfig serverConfig = ServerConfig(
    port: const String.fromEnvironment('SERVER_PORT', defaultValue: "3303"),
    fallbackPort: const String.fromEnvironment(
      'SERVER_FALLBACK_PORT',
      defaultValue: "3309",
    ),
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
