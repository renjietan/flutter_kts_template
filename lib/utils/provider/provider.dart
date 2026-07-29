import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/utils/provider/keyloader.provider.dart';
import 'package:flutter_kts_template/utils/provider/radios.provider.dart';
import 'package:flutter_kts_template/utils/provider/user.provider.dart';
import 'package:provider/provider.dart';

import 'menu.provider.dart';

//状态管理
class ProviderStore {
  ProviderStore._internal();

  //全局初始化
  static MultiProvider init({
    required List<RadiosEntity> radios,
    required String userInfo,
    required Widget child,
  }) {
    GlobalLogger.logInfo("Provider start");
    //多个Provider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: UserProvider(userInfo)),
        ChangeNotifierProvider.value(value: MenuProvider(0)),
        ChangeNotifierProvider.value(value: RadiosProvider(radios)),
        ChangeNotifierProvider.value(value: KeyLoaderProvider([])),
      ],
      child: child,
    );
  }

  //获取值 of(context)  这个会引起页面的整体刷新，如果全局是页面级别的
  static T value<T>(BuildContext context, {bool listen = false}) {
    return Provider.of<T>(context, listen: listen);
  }

  //获取值 of(context)  这个会引起页面的整体刷新，如果全局是页面级别的
  static T of<T>(BuildContext context, {bool listen = true}) {
    return Provider.of<T>(context, listen: listen);
  }

  // 不会引起页面的刷新，只刷新了 Consumer 的部分，极大地缩小你的控件刷新范围
  static Consumer connect<T>({builder, child}) {
    return Consumer<T>(builder: builder, child: child);
  }
}
