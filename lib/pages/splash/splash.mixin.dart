import 'package:flutter/material.dart';
import 'package:flutter_kts_template/utils/shared.dart';
import 'package:go_router/go_router.dart';

import '../../core/databaseManager/databaseManager.dart';
import '../../core/express.dart';

mixin SplashMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // 初始化 数据库
    DatabaseManager.init().then((_) => Express.start());
    countDown();
  }

  //倒计时
  void countDown() {
    var duration = const Duration(seconds: 2);
    Future.delayed(duration, goHomePage);
  }

  //页面跳转
  void goHomePage() {
    String? userinfo = Shared.getUserInfo();
    context.go('/home');
    // Navigator.of(context).pushReplacementNamed('/home');
    if (userinfo != null && userinfo.isNotEmpty) {
      // Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}