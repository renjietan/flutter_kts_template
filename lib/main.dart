import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/express.dart';

import 'core/rtc/managers/udp/udp.manager.dart';
import 'init/app_init.dart';
import 'logger/logger.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  AppInit.run();
  ProcessSignal.sigint.watch().listen((_) async {
    GlobalLogger.logWTF("1、准备关闭数据库...");
    DatabaseManager.instance.close();
    GlobalLogger.logWTF("2、数据库已关闭，开始停止服务");
    await Express.stop();
    GlobalLogger.logWTF("3、服务已停止");
    await UdpManager().disconnect();
    exit(0);
  });
}
