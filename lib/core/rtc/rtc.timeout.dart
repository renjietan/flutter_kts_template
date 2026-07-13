import 'dart:async';

class TimeoutManager {
  // 私有构造函数，防止外部实例化（保证唯一实例）
  TimeoutManager._();

  static final Map<String, Timer> _timers = {};

  static void setTimeout(String key, Duration delay, void Function() callback) {
    if (_timers.containsKey(key)) {
      _timers[key]?.cancel();
    }
    final timer = Timer(delay, () {
      callback();
      _timers.remove(key);
    });
    _timers[key] = timer;
  }

  static void clearTimeout(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  static void clearAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  static bool hasTimer(String key) => _timers.containsKey(key);
}
