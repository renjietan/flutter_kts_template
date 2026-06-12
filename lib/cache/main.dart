// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_kts_template/config/config.dart';
// import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
// import 'package:flutter_kts_template/core/express.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'i18n/handle/translations.g.dart';
// import 'icons/hy_icons.dart';
// import 'logger/logger.dart';
// import 'objectbox.g.dart';
//
//
// void main() async {
//
//   WidgetsFlutterBinding.ensureInitialized();
//   // LocaleSettings.setPluralResolver(language: "zh");
//   LocaleSettings.useDeviceLocale(); // initialize with the right locale
//   GlobalLogger.logInfo(AppConfig.dataBaseConfig.name);
//   await DatabaseManager.init();
//
//   // 后端服务
//   await Express.start();
//   GlobalLogger.logDebug("Server start  ::${AppConfig.serverConfig.port}");
//   ProcessSignal.sigint.watch().listen((_) async {
//     GlobalLogger.logWTF("关闭数据库...");
//     DatabaseManager.instance.close();
//     GlobalLogger.logWTF("数据库已关闭，开始停止服务");
//     await Express.stop();
//     GlobalLogger.logWTF("服务已停止");
//     exit(0);
//   });
//
//   runApp(
//     TranslationProvider(
//       child: MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//
//     return MaterialApp(
//       title: 'Flutter Demo',
//       locale: TranslationProvider.of(context).flutterLocale,
//       supportedLocales: AppLocaleUtils.supportedLocales,
//       localizationsDelegates: [...GlobalMaterialLocalizations.delegates],
//       home: MyHomePage(),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   @override
//   void initState() {
//     super.initState();
//
//     LocaleSettings.getLocaleStream().listen((event) {
//       print('locale changed1: $event');
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // get t variable, will trigger rebuild on locale change
//     // otherwise just call t directly (if locale is not changeable)
//     final t = Translations.of(context);
//     return Scaffold(
//       appBar: AppBar(title: Text(t.app.title)),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(t.common.itemCount(n: _counter, count: _counter)),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//
//               // lets loop over all supported locales
//               children: AppLocale.values.map((locale) {
//                 // active locale
//                 AppLocale activeLocale = LocaleSettings.currentLocale;
//
//                 // typed version is preferred to avoid typos
//                 bool active = activeLocale == locale;
//
//                 return Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: OutlinedButton(
//                     style: OutlinedButton.styleFrom(
//                       backgroundColor: active ? Colors.blue.shade100 : null,
//                     ),
//                     onPressed: () {
//                       // locale change, will trigger a rebuild (no setState needed)
//                       LocaleSettings.setLocale(locale);
//                     },
//                     child: Text(
//                       locale.languageTag == "zh"
//                           ? t.settings.zh
//                           : t.settings.en,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _counter++;
//           });
//         },
//         tooltip: t.common.welcome(appName: 'Slang'), // using extension method
//         child: Icon(HyIcons.xiangzuojiantou),
//       ),
//     );
//   }
// }
