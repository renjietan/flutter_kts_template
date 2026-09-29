import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';

/// 一条收到的 UDP 数据报：载荷 + 来源 IP。
///
/// 来源 IP 用于扫描阶段按设备去重（`Scan:success` 不带 ID，只能靠来源 IP 区分）。
class UpdateDatagram {
  const UpdateDatagram({required this.data, required this.sourceIp});

  final Uint8List data;
  final String sourceIp;
}

/// 自更新 UDP 广播传输抽象。
///
/// 状态机只依赖该接口，便于用 mock 做单测；真实 RawDatagramSocket 实现单独接入。
abstract class UpdateTransport {
  Future<void> send(Uint8List data);

  Stream<UpdateDatagram> get replies;

  Future<void> close();
}

/// 广播会话状态机。
///
/// 封装「发指令 → 启动超时器 → 等回复清除 → 发下一条」的通用原语，
/// 以及超时重发（连续 3 次终止）和统一复位（关 UDP + 停止后续操作）。
class UpdateSession {
  UpdateSession({required this.transport}) {
    _sub = transport.replies.listen(_onDatagram);
  }

  final UpdateTransport transport;
  StreamSubscription<UpdateDatagram>? _sub;
  final List<UpdateReply> _buffer = [];
  final StreamController<UpdateReply> _notifier =
      StreamController<UpdateReply>.broadcast();

  static const authTimeout = Duration(seconds: 5);
  static const versionTimeout = Duration(seconds: 5);
  static const transferTimeout = Duration(seconds: 3);
  static const validTimeout = Duration(seconds: 5);
  static const maxAttempts = 3;

  bool _disposed = false;

  void _onDatagram(UpdateDatagram datagram) {
    final reply = UpdateProtocol.parseReply(datagram.data);
    if (reply == null) {
      return;
    }
    _buffer.add(reply);
    if (!_notifier.isClosed) {
      _notifier.add(reply);
    }
  }


  /// 提取并移除 update 回执（`update_ok` / `update_fail`），供传输阶段窗口之间
  /// 保留提前到达的回执；不回删 valid / write 回复。
  List<UpdateReply> extractUpdateReplies() {
    final extracted = _buffer.whereType<UpdateResultReply>().toList();
    _buffer.removeWhere((r) => r is UpdateResultReply);
    return extracted;
  }

  /// 提取并移除后续阶段回复（valid / update）。
  ///
  /// 暂停传输时调用：清掉当前阶段的 ACK（fileAck / packet_ok / packet_fail），
  /// 但保留 `valid_ok` / `valid_fail` / `update_ok` / `update_fail`，避免
  /// 「最后一包触发的 valid_ok」被丢弃导致校验超时。
  List<UpdateReply> extractLaterReplies() {
    final extracted = _buffer
        .where((r) => r is ValidReply || r is WriteResultReply || r is UpdateResultReply)
        .toList();
    _buffer.removeWhere(
      (r) => r is ValidReply || r is WriteResultReply || r is UpdateResultReply,
    );
    return extracted;
  }

  /// 发送并等待第一个匹配回复；超时重发，最多 [attempts] 次。
  ///
  /// 适用于 file / packet / valid 这类「一个命令对应一个回复」的场景。
  Future<T?> request<T extends UpdateReply>({
    required Uint8List command,
    required Duration timeout,
    required bool Function(UpdateReply reply) matches,
    int attempts = maxAttempts,
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (_disposed) {
        return null;
      }
      final reply = await _requestOnce(command, timeout, matches);
      if (reply != null) {
        return reply as T;
      }
    }
    return null;
  }

  /// 发送并在整个窗口内收集所有匹配回复；窗口内无回复则重发。
  ///
  /// 适用于 auth / version 这类「广播后多设备回复」的场景。
  Future<List<T>> collect<T extends UpdateReply>({
    required Uint8List command,
    required Duration timeout,
    required bool Function(UpdateReply reply) matches,
    int attempts = maxAttempts,
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (_disposed) {
        return const [];
      }
      final replies = await _collectOnce(command, timeout, matches);
      if (replies.isNotEmpty) {
        return replies.cast<T>();
      }
    }
    return const [];
  }

  /// 发送并收集，直到 [isDone] 满足或超时；未满足则重发，最多 [attempts] 次。
  ///
  /// 适用于 file / packet 这类「广播后需所有目标设备都 ACK」的场景。
  Future<List<T>> collectUntil<T extends UpdateReply>({
    required Uint8List command,
    required Duration timeout,
    required bool Function(UpdateReply reply) matches,
    required bool Function(List<T> collected) isDone,
    int attempts = maxAttempts,
    Future<void>? cancelSignal,
  }) async {
    List<T> last = const [];
    for (var i = 0; i < attempts; i++) {
      if (_disposed) {
        return const [];
      }
      final replies = await _collectOnce(
        command,
        timeout,
        matches,
        isDone: (collected) => isDone(collected.cast<T>()),
        cancelSignal: cancelSignal,
      );
      final typed = replies.cast<T>();
      last = typed;
      if (isDone(typed)) {
        return typed;
      }
    }
    // attempts 用尽仍未满足 isDone 时，返回最后一次收集到的回复，
    // 供调用方处理 `sequence:S` 这类「未完全 ACK 但仍有价值」的回复。
    return last;
  }

  /// 不发送指令，仅等待并收集，直到 [isDone] 满足或超时（无重试）。
  ///
  /// 适用于 valid 这类「由 CPDC 主动发起、CPDS 只收集」的场景。
  Future<List<T>> waitFor<T extends UpdateReply>({
    required Duration timeout,
    required bool Function(UpdateReply reply) matches,
    required bool Function(List<T> collected) isDone,
  }) async {
    if (_disposed) {
      return const [];
    }
    final replies = await _collectOnce(
      null,
      timeout,
      matches,
      isDone: (collected) => isDone(collected.cast<T>()),
    );
    return replies.cast<T>();
  }

  /// 复位：关闭 UDP 并禁止后续请求/收集。
  Future<void> reset() async {
    // 无论是否已复位，都先清空缓存，保证幂等调用仍能释放残留回复。
    _buffer.clear();
    if (_disposed) {
      return;
    }
    _disposed = true;
    // 先同步触发 close，确保关闭标志立即置位（避免上层对 closed 状态的时序依赖）。
    final closeFuture = transport.close();
    await _sub?.cancel();
    await _notifier.close();
    await closeFuture;
  }

  Future<UpdateReply?> _requestOnce(
    Uint8List command,
    Duration timeout,
    bool Function(UpdateReply) matches,
  ) async {
    _buffer.clear();
    final completer = Completer<UpdateReply>();
    late StreamSubscription<UpdateReply> sub;
    sub = _notifier.stream.listen((reply) {
      if (matches(reply) && !completer.isCompleted) {
        completer.complete(reply);
      }
    });
    await transport.send(command);
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      return null;
    } finally {
      await sub.cancel();
    }
  }

  Future<List<UpdateReply>> _collectOnce(
    Uint8List? command,
    Duration timeout,
    bool Function(UpdateReply) matches, {
    bool Function(List<UpdateReply> collected)? isDone,
    Future<void>? cancelSignal,
  }) async {
    if (command != null) {
      _buffer.clear();
    }
    final done = Completer<void>();
    void check() {
      final matching = _buffer.where(matches).toList();
      if (isDone != null && isDone(matching) && !done.isCompleted) {
        done.complete();
      }
    }

    late StreamSubscription<UpdateReply> sub;
    sub = _notifier.stream.listen((_) => check());
    if (command != null) {
      await transport.send(command);
    }
    check();
    try {
      if (isDone != null) {
        if (cancelSignal != null) {
          await Future.any([done.future, cancelSignal]).timeout(timeout);
        } else {
          await done.future.timeout(timeout);
        }
      } else {
        await Future<void>.delayed(timeout);
      }
    } on TimeoutException {
      // 超时后返回已收集到的回复。
    } finally {
      await sub.cancel();
    }
    return _buffer.where(matches).toList();
  }
}