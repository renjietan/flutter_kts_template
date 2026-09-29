import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';

/// 发现阶段的状态。
enum ScanState { idle, scanning, done, cancelled }

/// 发现阶段控制器。
///
/// 每秒发送一次 "Scan"（共 [duration] 时长），统计收到的 "Scan:success" 数量，
/// 倒计时结束后停止接收（丢弃后续回复）。
///
/// [tick] 与 [duration] 可注入，便于测试用更短的时间片；生产环境为 1 秒 / 10 秒。
class ScanController extends ChangeNotifier {
  ScanController({
    required this.transport,
    this.duration = const Duration(seconds: 10),
    this.tick = const Duration(seconds: 1),
  }) : _totalSteps = _steps(duration, tick);

  final UpdateTransport transport;
  final Duration duration;
  final Duration tick;

  final int _totalSteps;
  int _remainingSteps = 0;
  int _deviceCount = 0;
  ScanState _state = ScanState.idle;
  bool _acceptReplies = true;
  Timer? _timer;
  StreamSubscription<UpdateDatagram>? _sub;
  final Set<String> _seenIps = {};

  ScanState get state => _state;
  int get deviceCount => _deviceCount;
  bool get hasDevices => _deviceCount > 0;

  /// 剩余秒数（当 [tick] 为 1 秒时即真实秒数）。
  int get remainingSeconds => _remainingSteps;

  /// 总秒数（当 [tick] 为 1 秒时即真实总秒数）。
  int get totalSeconds => _totalSteps;

  /// 已流逝比例（0.0 ~ 1.0）。
  double get progress =>
      _totalSteps <= 0 ? 0 : 1 - (_remainingSteps / _totalSteps);

  static int _steps(Duration duration, Duration tick) {
    final ms = duration.inMilliseconds;
    final tickMs = tick.inMilliseconds;
    if (tickMs <= 0 || ms <= 0) {
      return 1;
    }
    final steps = ms ~/ tickMs;
    return steps < 1 ? 1 : steps;
  }

  Future<void> start() async {
    _state = ScanState.scanning;
    _remainingSteps = _totalSteps;
    _deviceCount = 0;
    _acceptReplies = true;
    _seenIps.clear();
    notifyListeners();

    _sub = transport.replies.listen((datagram) {
      if (!_acceptReplies || _state != ScanState.scanning) {
        return;
      }
      if (UpdateProtocol.parseReply(datagram.data) is ScanAckReply) {
        // `Scan:success` 不带 ID，按来源 IP 去重，避免同一设备被计数多次。
        if (_seenIps.add(datagram.sourceIp)) {
          _deviceCount++;
          notifyListeners();
        }
      }
    });

    await transport.send(UpdateProtocol.encodeScan());

    _timer = Timer.periodic(tick, (_) {
      if (_state != ScanState.scanning) {
        return;
      }
      _remainingSteps--;
      if (_remainingSteps <= 0) {
        _finish();
      } else {
        transport.send(UpdateProtocol.encodeScan());
        notifyListeners();
      }
    });
  }

  void _finish() {
    _state = ScanState.done;
    _acceptReplies = false;
    _timer?.cancel();
    _sub?.cancel();
    notifyListeners();
  }

  /// 提前结束扫描（扫到设备后点【下一步】）：停计时器、不再发 `Scan`、
  /// 丢弃后续 `Scan:success`，状态置 done。
  void finishEarly() {
    if (_state != ScanState.scanning) {
      return;
    }
    _finish();
  }

  Future<void> cancel() async {
    if (_state == ScanState.done || _state == ScanState.cancelled) {
      return;
    }
    _state = ScanState.cancelled;
    _acceptReplies = false;
    _timer?.cancel();
    _sub?.cancel();
    _deviceCount = 0;
    _seenIps.clear();
    notifyListeners();
    await transport.close();
  }

  /// 全量复位扫描残留：清空计数、IP 去重集合、计时器与订阅。
  ///
  /// 不关闭 [transport]，由 [UpdateSession] 统一负责关 UDP。
  void reset() {
    _timer?.cancel();
    _sub?.cancel();
    _state = ScanState.cancelled;
    _acceptReplies = false;
    _deviceCount = 0;
    _remainingSteps = 0;
    _seenIps.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
