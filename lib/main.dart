import 'dart:io';

import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/express.dart';
import 'init/app_init.dart';
import 'logger/logger.dart';


void main() {
  AppInit.run();
  ProcessSignal.sigint.watch().listen((_) async {
    GlobalLogger.logWTF("关闭数据库...");
    DatabaseManager.instance.close();
    GlobalLogger.logWTF("数据库已关闭，开始停止服务");
    await Express.stop();
    GlobalLogger.logWTF("服务已停止");
    exit(0);
  });
}


