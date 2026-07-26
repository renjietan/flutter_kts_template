//默认App的启动
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/router/router.dart';
import 'package:flutter_kts_template/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:unified_popups/unified_popups.dart';

import '../i18n/handle/translations.g.dart';
import '../main.dart';
import '../utils/provider/provider.dart';
import '../utils/shared.dart';

class DefaultApp {
  //运行app
  static void run() async {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    LocaleSettings.useDeviceLocale();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFF5AA6FD),
        systemNavigationBarDividerColor: null,
        statusBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    );
    // 初始化缓存
    await Shared.init();

    String userInfo = Shared.getUserInfo() ?? '';
    userInfo = "123";
    runApp(
      ProviderStore.init(
        child: TranslationProvider(child: MyApp()),
        userInfo: userInfo,
        radios: [],
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 添加 一个标记位，防止popup重复初始化
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 关键：在第一帧绘制完成后移除原生启动页
    // 保证 Flutter 已经准备好显示内容了，不会闪烁
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isInitialized) {
        // 移除启动页
        FlutterNativeSplash.remove();
        isInitialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1200, 1980),
      minTextAdapt: true, // 确保字体在小屏幕上不会缩得太小
      splitScreenMode: true, // 确保分屏、旋转屏幕或多窗口下布局正常
      builder: (context, child) {
        PopupManager.initialize(navigatorKey: rootNavigatorKey);
        return MaterialApp.router(
          // 任务管理器中应用名称，主要影响外部系统显示
          title: AppConfig.appName,
          // 不显示页面中 DEBUG 横幅
          debugShowCheckedModeBanner: false,
          // navigatorKey: AppConfig.navigatorKey,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: [...GlobalMaterialLocalizations.delegates],
          theme: AppTheme.dark,
          routerConfig: router,
        );
      },
      // child: SplashPage(),
    );
  }
}
