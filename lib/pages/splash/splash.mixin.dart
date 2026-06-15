import 'package:flutter/material.dart';
import 'package:flutter_kts_template/utils/provider/provider.dart';
import 'package:flutter_kts_template/utils/provider/user_provider.dart';
import 'package:flutter_kts_template/utils/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/databaseManager/databaseManager.dart';
import '../../core/express.dart';

mixin SplashMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // 提前声明，放在异步中，会出现警告，不够安全
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    init().then((_) {
        String userInfo = Shared.getUserInfo() ?? '';
        userProvider.userInfo = userInfo;
        if(mounted) {
          goHomePage();
        }
    });
  }
  Future init() async {
    await Shared.init();
    await DatabaseManager.init();
    await Express.start();
  }
  //页面跳转
  void goHomePage() {
    String? userinfo = Shared.getUserInfo();
    // 通过回调告知外层已完成启动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // context.pushReplacementNamed('/paramsInject');
      context.go("paramsInject");
    });
    if (userinfo != null && userinfo.isNotEmpty) {
      // Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}