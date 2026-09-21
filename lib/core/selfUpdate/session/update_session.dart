import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';

/// 自更新 UDP 广播传输抽象。
///
/// 状态机只依赖该接口，便于用 mock 做单测；真实 RawDatagramSocket 实现单独接入。
abstract class UpdateTransport {
  Future<void> send(Uint8List data);

  Stream<Uint8List> get replies;

  Future<void> close();
}

/// 广播会话状态机。
///
/// 封装「发指令 → 启动超时器 → 等回复清除 → 发下一条」的通用原语，
/// 以及超时重发（连续 3 次终止）和统一复位（关 UDP + 停止后续操作）。
class UpdateSession {
  UpdateSession({required this.transport});

  final UpdateTransport transport;

  static const authTimeout = Duration(seconds: 5);
  static const versionTimeout = Duration(seconds: 5);
  static const transferTimeout = Duration(seconds: 3);
  static const validTimeout = Duration(seconds: 5);
  static const maxAttempts = 3;

  bool _disposed = false;

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
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (_disposed) {
        return const [];
      }
      final replies = await _collectOnce(
        command,
        timeout,
        matches,
        isDone: (collected) => isDone(collected.cast<T>()),
      );
      final typed = replies.cast<T>();
      if (isDone(typed)) {
        return typed;
      }
    }
    return const [];
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
    if (_disposed) {
      return;
    }
    _disposed = true;
    await transport.close();
  }

  Future<UpdateReply?> _requestOnce(
    Uint8List command,
    Duration timeout,
    bool Function(UpdateReply) matches,
  ) async {
    final completer = Completer<UpdateReply>();
    late StreamSubscription<Uint8List> sub;
    sub = transport.replies.listen((bytes) {
      final reply = UpdateProtocol.parseReply(bytes);
      if (reply != null && matches(reply) && !completer.isCompleted) {
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
    bool Function(UpdateReply) matches,
    {bool Function(List<UpdateReply> collected)? isDone}
  ) async {
    final replies = <UpdateReply>[];
    final done = Completer<void>();
    late StreamSubscription<Uint8List> sub;
    sub = transport.replies.listen((bytes) {
      final reply = UpdateProtocol.parseReply(bytes);
      if (reply != null && matches(reply)) {
        replies.add(reply);
        if (isDone != null &&
            isDone(replies) &&
            !done.isCompleted) {
          done.complete();
        }
      }
    });
    if (command != null) {
      await transport.send(command);
    }
    try {
      if (isDone != null) {
        await done.future.timeout(timeout);
      } else {
        await Future<void>.delayed(timeout);
      }
    } on TimeoutException {
      // 超时后返回已收集到的回复。
    } finally {
      await sub.cancel();
    }
    return replies;
  }
}
