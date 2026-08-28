//应用初始化
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/logger/logger.dart';

import 'default_app.dart';

class AppInit {
  static void run() {
    //捕获异常
    catchException(() => DefaultApp.run());
  }

  ///异常捕获处理
  static void catchException<T>(T Function() callback) {
    //捕获异常的回调
    FlutterError.onError = (FlutterErrorDetails details) {
      reportErrorAndLog(details);
    };
    runZoned<Future<void>>(
          () async {
        callback();
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          collectLog(parent, zone, line); // 收集日志
        },
      ),
      //未捕获的异常的回调
      // ignore: deprecated_member_use
      onError: (Object obj, StackTrace stack) {
        var details = makeDetails(obj, stack);
        reportErrorAndLog(details);
      },
    );
  }

  //日志拦截, 收集日志
  static void collectLog(ZoneDelegate parent, Zone zone, String line) {
    parent.print(zone, "日志拦截: $line");
  }

  //上报错误和日志逻辑
  static void reportErrorAndLog(FlutterErrorDetails details) {
    if (_isBenignWindowsKeyboardAssertion(details)) {
      // Windows 桌面端已知引擎 Bug（flutter/flutter#169447，修复 PR #178523）：
      // 窗口在按键期间失焦会丢失 WM_KEYUP，焦点恢复后再次按下会触发
      // hardware_keyboard.dart 里“KeyDownEvent already pressed”的断言。
      // 该断言仅在 debug/profile 生效且非致命，过滤掉以免污染错误日志。
      // 功能层面（keydown 被丢导致 Ctrl+V 等失效）已由
      // KeyboardShortcutRecovery 在应用层兜底恢复；彻底修复需升级引擎。
      GlobalLogger.logDebug(
        'Ignored known benign Windows keyboard assertion: ${details.exception}',
      );
      return;
    }
    final errorString = '异常: ${details.exception}\n堆栈: ${details.stack}';
    GlobalLogger.logError(errorString);
  }

  /// 判断是否为 Windows 桌面端已知的良性按键断言
  /// （hardware_keyboard.dart: KeyDownEvent 重复按下）。
  static bool _isBenignWindowsKeyboardAssertion(FlutterErrorDetails details) {
    final Object? ex = details.exception;
    if (ex is! AssertionError) {
      return false;
    }
    final String message = ex.toString();
    return message.contains('hardware_keyboard.dart') &&
        message.contains(
          'A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed',
        );
  }

  // 构建错误信息
  static FlutterErrorDetails makeDetails(Object obj, StackTrace stack) {
    return FlutterErrorDetails(exception: obj, stack: stack);
  }
}
