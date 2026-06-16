import 'package:flutter/material.dart';
import 'package:flutter_kts_template/utils/provider/user_provider.dart';
import 'package:flutter_kts_template/utils/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../core/databaseManager/databaseManager.dart';
import '../../core/express.dart';
import '../../main.dart';

mixin SplashMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // 提前声明，放在异步中，会出现警告，不够安全
    UserProvider userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    init().then((_) {
      String userInfo = Shared.getUserInfo() ?? '';
      userProvider.userInfo = userInfo;
      if (mounted) {
        goHomePage();
      }
    });
  }

  Future init() async {
    // 初始化缓存
    await Shared.init();
    // 初始化数据库
    await DatabaseManager.init();
    // 初始化服务
    await Express.start();
  }

  //页面跳转
  void goHomePage() {
    String? userinfo = Shared.getUserInfo();
    // 确保 MaterialApp 构建完毕
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go("paramsInject");
      PopupManager.initialize(navigatorKey: rootNavigatorKey);
    });
    if (userinfo != null && userinfo.isNotEmpty) {
      // Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
