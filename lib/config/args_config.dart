import 'package:args/args.dart';
import 'package:flutter/foundation.dart';

/// 启动参数管理器（单例）
///
/// 负责解析 `main(List<String> args)` 收到的命令行参数，
/// 并在未传参时根据编译模式给出合理的默认值。
///
/// 用法：
///   void main(List<String> args) {
///     ArgsConfig.instance.init(args);
///     runApp(const MyApp());
///   }
///
///   // 之后任意位置读取
///   final level = ArgsConfig.instance.logLevel;
class ArgsConfig {
  ArgsConfig._();
  static final ArgsConfig instance = ArgsConfig._();

  // ───────────── 解析器定义 ─────────────
  static final ArgParser _parser = ArgParser()
    ..addOption(
      'log-level',
      abbr: 'l',
      allowed: ['trace', 'debug', 'info', 'warn', 'error'],
      help: '日志级别。不传时：Debug 构建默认 debug，Release 构建默认 info。',
    );

  ArgResults? _results;
  bool _initialized = false;

  /// 是否已完成初始化
  bool get isInitialized => _initialized;

  // ───────────── 初始化 ─────────────

  /// 在 runApp 之前调用。可重复调用，但只有第一次生效。
  void init(List<String> args) {
    if (_initialized) {
      debugPrint('[ArgsConfig] 已初始化，忽略重复调用');
      return;
    }

    try {
      _results = _parser.parse(args);
    } on FormatException catch (e) {
      // 参数不合法（例如未知选项、值不在 allowed 列表内）
      debugPrint('[ArgsConfig] 参数解析失败: ${e.message}');
      debugPrint('[ArgsConfig] 使用空参数 + 默认值继续启动');
      _results = _parser.parse(const []);
    }

    _initialized = true;

    debugPrint('[ArgsConfig] 启动参数摘要 → $this');
  }

  // ───────────── 访问器 ─────────────
  /// 日志级别：优先取 --log-level，未传时按编译模式回退
  String get logLevel {
    final v = _results?['log-level'] as String?;
    if (v != null) return v;
    // Debug 构建默认 debug，Release 构建默认 info。
    return kReleaseMode ? 'info' : 'debug';
  }

  // ───────────── 辅助 ─────────────

  /// 帮助文本
  String get usage => _parser.usage;

  /// 导出为 Map，便于写日志或持久化
  Map<String, dynamic> toMap() => {
    'log-level': logLevel,
    'releaseMode': kReleaseMode,
  };

  @override
  String toString() => toMap().toString();
}
