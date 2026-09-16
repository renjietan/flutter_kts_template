import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/utils/director.dart';
import 'log_category.dart';

/// 文件日志写入器：
/// - 按天建立目录 logs/yyyy-MM-dd/
/// - 按类别写 `<category>.log`，并同步写 all.log
/// - 普通日志异步写；错误日志同步写；崩溃/退出前可同步 flush
class LogFileWriter {
  LogFileWriter._();
  static final LogFileWriter instance = LogFileWriter._();

  Directory? _logsRoot;
  String _today = '';

  final List<_PendingLine> _pending = [];
  bool _draining = false;

  bool get isReady => _logsRoot != null;

  Future<void> init() async {
    if (_logsRoot != null) return;
    _logsRoot = await DirectoryManager.instance.getLogsDirectory();
  }

  void writeAsync(LogCategory category, String line) {
    if (_logsRoot == null) return;
    _pending.add(_PendingLine(category, line));
    _drain();
  }

  void writeSync(LogCategory category, String line) {
    if (_logsRoot == null) return;
    _appendSync(category, line);
  }

  void flushSync() {
    if (_logsRoot == null) return;
    while (_pending.isNotEmpty) {
      final entry = _pending.removeAt(0);
      _appendSync(entry.category, entry.line);
    }
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty) {
        final entry = _pending.removeAt(0);
        await _appendAsync(entry.category, entry.line);
      }
    } finally {
      _draining = false;
    }
  }

  Directory _todayDir() {
    final today = _dateStr(DateTime.now());
    if (_today != today) {
      _today = today;
      Directory(p.join(_logsRoot!.path, today)).createSync(recursive: true);
    }
    return Directory(p.join(_logsRoot!.path, _today));
  }

  void _appendSync(LogCategory category, String line) {
    final dir = _todayDir();
    for (final name in <String>[category.fileName, 'all.log']) {
      File(p.join(dir.path, name))
          .writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    }
  }

  Future<void> _appendAsync(LogCategory category, String line) async {
    final dir = _todayDir();
    for (final name in <String>[category.fileName, 'all.log']) {
      await File(p.join(dir.path, name))
          .writeAsString('$line\n', mode: FileMode.append, flush: true);
    }
  }

  String _dateStr(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }
}

class _PendingLine {
  const _PendingLine(this.category, this.line);
  final LogCategory category;
  final String line;
}