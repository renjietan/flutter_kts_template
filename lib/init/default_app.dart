//默认App的启动
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/router/router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../i18n/handle/translations.g.dart';
import '../utils/provider/provider.dart';

class DefaultApp {
  //运行app
  static void run() async {
    WidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.setPluralResolver(
      locale: AppLocale.zh,
      cardinalResolver: (n, {zero, one, two, few, many, other}) {
        // 返回 'other' 表示总是使用翻译中定义的 'other' 键
        return other ?? 'other';
      },
    );
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

    runApp(ProviderStore.init(TranslationProvider(child: MyApp())));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1200, 1980),
      builder: (context, child) {
        return MaterialApp.router(
          // 任务管理器中应用名称，主要影响外部系统显示
          title: AppConfig.appName,
          // 不显示页面中 DEBUG 横幅
          debugShowCheckedModeBanner: false,
          // navigatorKey: AppConfig.navigatorKey,
          locale: TranslationProvider.of(
            context,
          ).flutterLocale, //设置这个可以使输入框文字垂直居中
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: [...GlobalMaterialLocalizations.delegates],
          theme: ThemeData.dark(),
          routerConfig: router,
        );
      },
      // child: SplashPage(),
    );
    // return material_app();
  }
}
