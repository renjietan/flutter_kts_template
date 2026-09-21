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
  StreamSubscription<Uint8List>? _sub;

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
    notifyListeners();

    _sub = transport.replies.listen((bytes) {
      if (!_acceptReplies || _state != ScanState.scanning) {
        return;
      }
      if (UpdateProtocol.parseReply(bytes) is ScanAckReply) {
        _deviceCount++;
        notifyListeners();
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

  Future<void> cancel() async {
    if (_state == ScanState.done || _state == ScanState.cancelled) {
      return;
    }
    _state = ScanState.cancelled;
    _timer?.cancel();
    _sub?.cancel();
    notifyListeners();
    await transport.close();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
