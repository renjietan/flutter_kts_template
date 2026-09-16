import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';

import 'log_category.dart';
import 'log_file_writer.dart';

export 'log_category.dart';

class GlobalLogger {
  static Logger L = Logger(printer: HybridPrinter(PrefixPrinter(
    SimplePrinter(printTime: true),
    trace: '[跟踪]',
    info: '[信息]',
    warning: '[警告]',
    // debug: '[调试]',
    // error: '[错误]',
    // fatal: '[灾难]'
  ), debug: PrettyPrinter(), error: PrettyPrinter(), fatal: PrettyPrinter()));

  static LogCategory _category = LogCategory.http;

  /// 初始化文件日志（解析 logs 目录）
  static Future<void> init() => LogFileWriter.instance.init();

  /// 在指定类别下执行 body，结束（含异常/提前返回）后必定还原类别
  static Future<T> runWithCategory<T>(
    LogCategory category,
    Future<T> Function() body,
  ) async {
    final prev = _category;
    if (category != prev) {
      _category = category;
      _consoleOnly('日志类别切换: ${prev.name} -> ${category.name}');
    }
    try {
      return await body();
    } finally {
      if (_category != prev) {
        final from = _category;
        _category = prev;
        _consoleOnly('日志类别还原: ${from.name} -> ${prev.name}');
      }
    }
  }

  /// 崩溃/退出前同步 flush 未写完的异步日志
  static void flushSync() => LogFileWriter.instance.flushSync();

  /// 仅打印到控制台，不写入文件
  static void _consoleOnly(String msg) {
    L.i(msg, time: DateTime.now());
  }

  static void logTrace(String msg) {
    L.t(msg, time: DateTime.now());
    _file('TRACE', msg, sync: false);
  }

  static void logDebug(String msg) {
    L.d(msg, time: DateTime.now());
    _file('DEBUG', msg, sync: false);
  }

  static void logInfo(String msg) {
    L.i(msg, time: DateTime.now());
    _file('INFO', msg, sync: false);
  }

  static void logWarn(String msg) {
    L.w(msg, time: DateTime.now());
    _file('WARN', msg, sync: false);
  }

  static void logError(String msg) {
    L.e(msg, time: DateTime.now());
    _file('ERROR', msg, sync: true);
  }

  static void logWTF(String msg) {
    L.f(msg, time: DateTime.now());
    _file('WTF', msg, sync: true);
  }

  static void _file(String level, String msg, {required bool sync}) {
    final line = '[$_timestamp()] [$level] ${_beautify(msg)}';
    if (sync) {
      LogFileWriter.instance.writeSync(_category, line);
      LogFileWriter.instance.flushSync();
    } else {
      LogFileWriter.instance.writeAsync(_category, line);
    }
  }

  static String _timestamp() {
    final dt = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  /// 尝试把消息里的 JSON/数组部分美化（缩进换行）
  static String _beautify(String msg) {
    final brace = msg.indexOf('{');
    final bracket = msg.indexOf('[');
    int idx;
    if (brace < 0) {
      idx = bracket;
    } else if (bracket < 0) {
      idx = brace;
    } else {
      idx = brace < bracket ? brace : bracket;
    }
    if (idx < 0) return msg;

    final prefix = msg.substring(0, idx);
    final candidate = msg.substring(idx);
    try {
      final decoded = jsonDecode(candidate);
      return '$prefix${const JsonEncoder.withIndent('  ').convert(decoded)}';
    } catch (_) {
      return msg;
    }
  }
}