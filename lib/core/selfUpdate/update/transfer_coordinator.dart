import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/fail_reason_text.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

/// 设备标识键：类型#IP。
String deviceKey(String deviceType, String ip) => '$deviceType#$ip';

/// 传输阶段的状态机。
enum TransferState {
  idle,
  sendingFile,
  sendingPacket,
  paused,
  cancelled,
  finished,
}

/// 单个分包的发送结果。
sealed class _PacketSendOutcome {
  const _PacketSendOutcome();
}

/// 所有目标设备都回 `packet_ok`。
class _PacketSendSuccess extends _PacketSendOutcome {
  const _PacketSendSuccess();
}

/// `length` / `crc` 失败或超时，重试耗尽。
class _PacketSendFailure extends _PacketSendOutcome {
  const _PacketSendFailure();
}

/// 收到 `sequence:S`，需要把游标拉回缺失包号 S（1-based）从 S 顺序重发。
class _PacketSendResend extends _PacketSendOutcome {
  const _PacketSendResend(this.packetNumber);

  final int packetNumber;
}

/// 传输 + 校验流程编排。
///
/// 以「游标 + 子阶段」作为传输进度的唯一真源，发送幂等，暂停/继续/取消通过
/// 单一状态机驱动，避免多设备下多个 flag 叠加产生的竞态。
class TransferCoordinator {
  TransferCoordinator({
    required this.session,
    required this.controller,
    required this.storage,
    required this.baseName,
    this.transferTimeout = UpdateSession.transferTimeout,
    this.validTimeout = UpdateSession.validTimeout,
    this.receiptTimeout = const Duration(seconds: 60),
    this.writeTimeout = const Duration(seconds: 15),
  });

  final UpdateSession session;
  final UpdateStepController controller;
  final InstallPackageStorage storage;
  final String baseName;
  final Duration transferTimeout;
  final Duration validTimeout;
  final Duration receiptTimeout;
  final Duration writeTimeout;

  TransferState _state = TransferState.idle;
  TransferState _resumeState = TransferState.idle;
  int _cursor = 0;
  Completer<void> _pauseSignal = Completer<void>();
  Completer<void> _resumeSignal = Completer<void>();
  List<Uint8List> _packets = [];
  Uint8List? _fileCommand;
  Set<String> _deviceKeys = {};
  List<UpdateDevice> _selectedDevices = [];
  List<int> _prefix = [];
  final List<UpdateReply> _laterReplies = [];
  int _fileCrc32 = 0;
  int _filePacketCount = 0;
  int _fileTotalBytes = 0;
  String _fileName = '';

  TransferState get state => _state;

  /// 执行传输（步骤 3）与校验（步骤 4）。
  ///
  /// 返回是否成功进入后续写入阶段。
  Future<bool> run(List<UpdateDevice> selectedDevices) async {
    if (selectedDevices.isEmpty) {
      return false;
    }

    _selectedDevices = selectedDevices;
    _deviceKeys = selectedDevices
        .map((d) => deviceKey(d.type, d.rawIp))
        .toSet();
    _laterReplies.clear();

    controller.setActiveStep(3);
    controller.setStepStatus(3, StepStatus.running);

    // 去重类型并打包。
    final types = selectedDevices.map((d) => d.type).toSet();
    final zipBytes = await storage.buildTypeZip(
      baseName: baseName,
      deviceTypes: types,
    );
    if (zipBytes.isEmpty) {
      _terminate('未找到匹配的安装包');
      return false;
    }

    final crc32 = UpdateProtocol.crc32(zipBytes);
    _packets = UpdateProtocol.splitPackets(zipBytes);
    _fileCommand = UpdateProtocol.encodeFile(
      crc32: crc32,
      packetCount: _packets.length,
      totalBytes: zipBytes.length,
      fileName: '$baseName.zip',
    );
    _fileCrc32 = crc32;
    _filePacketCount = _packets.length;
    _fileTotalBytes = zipBytes.length;
    _fileName = '$baseName.zip';

    // 初始化传输进度。
    for (final device in selectedDevices) {
      device.status = '传输中';
      device.progress = 0;
      device.transferredBytes = 0;
      device.totalBytes = zipBytes.length;
    }

    // 分包载荷前缀和，用于按字节精确更新进度。
    _prefix = [];
    var accumulated = 0;
    for (final packet in _packets) {
      accumulated += packet.length;
      _prefix.add(accumulated);
    }

    _cursor = 0;
    _state = TransferState.sendingFile;
    _resumeState = TransferState.sendingFile;
    _pauseSignal = Completer<void>();
    _resumeSignal = Completer<void>();
    controller.setTransferStage(TransferStage.sending);

    final finished = await _runTransferLoop();
    if (!finished) {
      return false;
    }

    for (final device in selectedDevices) {
      device.progress = 1;
      device.transferredBytes = device.totalBytes;
    }
    controller.setTotalProgress(1);
    controller.setStepStatus(3, StepStatus.success);

    return await runValid();
  }

  Future<bool> _runTransferLoop() async {
    while (true) {
      if (_state == TransferState.cancelled) {
        return false;
      }
      if (_state == TransferState.paused) {
        controller.setTransferStage(TransferStage.paused);
        await _resumeSignal.future;
        _resumeSignal = Completer<void>();
        if (_state == TransferState.cancelled) {
          return false;
        }
        controller.setTransferStage(TransferStage.sending);
        continue;
      }
      if (_state == TransferState.sendingFile) {
        final ok = await _sendFileOnce();
        if (_state == TransferState.paused ||
            _state == TransferState.cancelled) {
          continue;
        }
        if (!ok) {
          _terminate('传输前置指令超时');
          return false;
        }
        _state = TransferState.sendingPacket;
        _resumeState = TransferState.sendingPacket;
        _cursor = 0;
        continue;
      }
      if (_state == TransferState.sendingPacket) {
        if (_cursor >= _packets.length) {
          _state = TransferState.finished;
          return true;
        }
        final outcome = await _sendPacketOnce(_cursor);
        if (_state == TransferState.paused ||
            _state == TransferState.cancelled) {
          continue;
        }
        if (outcome is _PacketSendResend) {
          final s = outcome.packetNumber;
          if (s >= 1 && s <= _packets.length) {
            _cursor = s - 1;
          }
          continue;
        }
        if (outcome is _PacketSendFailure) {
          _terminate('传输分包超时');
          return false;
        }
        // 成功：更新进度。
        for (final device in _selectedDevices) {
          device.transferredBytes = _prefix[_cursor];
          device.progress = device.totalBytes > 0
              ? device.transferredBytes / device.totalBytes
              : 0;
        }
        controller.setTotalProgress((_cursor + 1) / _packets.length);
        _cursor++;
        continue;
      }
      break;
    }
    return false;
  }

  Future<bool> _sendFileOnce() async {
    final acks = await session.collectUntil<UpdateReply>(
      command: _fileCommand!,
      timeout: transferTimeout,
      matches: (reply) => reply is FileAckReply,
      isDone: (collected) {
        final keys = collected.map(_replyKey).toSet();
        return keys.containsAll(_deviceKeys);
      },
      cancelSignal: _pauseSignal.future,
    );
    if (_state == TransferState.paused || _state == TransferState.cancelled) {
      return false;
    }
    final keys = acks.map(_replyKey).toSet();
    return keys.containsAll(_deviceKeys);
  }

  Future<_PacketSendOutcome> _sendPacketOnce(int cursor) async {
    for (var attempt = 0; attempt < UpdateSession.maxAttempts; attempt++) {
      if (_state != TransferState.sendingPacket) {
        return const _PacketSendFailure();
      }
      final replies = await session.collectUntil<UpdateReply>(
        command: _packets[cursor],
        timeout: transferTimeout,
        attempts: 1,
        matches: (reply) => reply is PacketOkReply || reply is PacketFailReply,
        isDone: (collected) {
          // 只在「所有目标设备都回 packet_ok」时提前结束窗口；
          // length/crc 与 sequence 都等整窗口结束后再处理。
          final ackKeys = collected
              .whereType<PacketOkReply>()
              .map((r) => deviceKey(r.deviceType, r.ip))
              .toSet();
          return ackKeys.containsAll(_deviceKeys);
        },
        cancelSignal: _pauseSignal.future,
      );
      if (_state == TransferState.paused || _state == TransferState.cancelled) {
        return const _PacketSendFailure();
      }

      // sequence 优先：回退到最小的缺失包号（最靠前的缺失包），
      // 让所有落后设备从该包开始依次补发。
      int? minMissing;
      for (final fail in replies.whereType<PacketFailReply>()) {
        final missing = fail.missingPacketNumber;
        if (missing != null &&
            (minMissing == null || missing < minMissing)) {
          minMissing = missing;
        }
      }
      if (minMissing != null) {
        return _PacketSendResend(minMissing);
      }

      final ackKeys = replies
          .whereType<PacketOkReply>()
          .map((r) => deviceKey(r.deviceType, r.ip))
          .toSet();
      final errorKeys = replies
          .whereType<PacketFailReply>()
          .where((r) => r.missingPacketNumber == null)
          .map((r) => deviceKey(r.deviceType, r.ip))
          .toSet();
      if (ackKeys.containsAll(_deviceKeys) && errorKeys.isEmpty) {
        return const _PacketSendSuccess();
      }
    }
    return const _PacketSendFailure();
  }

  /// 暂停：立即中断当前等待，游标不变，保留 valid/update 回复。
  void pause() {
    if (_state != TransferState.sendingFile &&
        _state != TransferState.sendingPacket) {
      return;
    }
    _resumeState = _state;
    _state = TransferState.paused;
    _laterReplies.addAll(session.extractLaterReplies());
    if (!_pauseSignal.isCompleted) {
      _pauseSignal.complete();
    }
    _pauseSignal = Completer<void>();
    controller.setTransferStage(TransferStage.paused);
  }

  /// 继续：从当前游标重发（幂等），全新发送等待。
  void resume() {
    if (_state != TransferState.paused) {
      return;
    }
    _state = _resumeState;
    controller.setTransferStage(TransferStage.sending);
    if (!_resumeSignal.isCompleted) {
      _resumeSignal.complete();
    }
  }

  /// 取消：中断传输并清空在途状态；关 UDP 与关闭弹窗由上层负责。
  ///
  /// 无论当前处于什么状态，都清空游标、分包、file 指令、目标设备集、
  /// 缓存的后续回复与暂停/继续信号，确保【取消/关闭】全量复位。
  void cancel() {
    _state = TransferState.cancelled;
    if (!_pauseSignal.isCompleted) {
      _pauseSignal.complete();
    }
    _pauseSignal = Completer<void>();
    if (!_resumeSignal.isCompleted) {
      _resumeSignal.complete();
    }
    _resumeSignal = Completer<void>();
    _cursor = 0;
    _packets = [];
    _fileCommand = null;
    _deviceKeys = {};
    _selectedDevices = [];
    _prefix = [];
    _laterReplies.clear();
    _resumeState = TransferState.idle;
    controller.setTransferStage(TransferStage.finished);
  }

  /// 校验阶段（步骤 4）：3 个独立 5 秒窗口广播 `valid:<file头>`。
  ///
  /// 返回是否「全部目标设备都回 valid_ok」；否则进入 validFailed 可恢复失败态。
  Future<bool> runValid() async {
    controller.setActiveStep(4);
    controller.setStepStatus(4, StepStatus.running);

    final command = UpdateProtocol.encodeValid(
      crc32: _fileCrc32,
      packetCount: _filePacketCount,
      totalBytes: _fileTotalBytes,
      fileName: _fileName,
    );

    var lastReplies = <ValidReply>[];
    for (var window = 0; window < UpdateSession.maxAttempts; window++) {
      final replies = await session.collectUntil<ValidReply>(
        command: command,
        timeout: validTimeout,
        attempts: 1,
        matches: (reply) => reply is ValidReply,
        isDone: (collected) {
          final okKeys = collected
              .where((r) => r.ok)
              .map((r) => deviceKey(r.deviceType, r.ip))
              .toSet();
          return okKeys.containsAll(_deviceKeys);
        },
      );
      lastReplies = replies;
      if (_allValidOk(lastReplies)) {
        break;
      }
    }

    _markValidDevices(lastReplies);

    if (_selectedDevices.every((d) => d.status == '校验通过')) {
      controller.setStepStatus(4, StepStatus.success);
      return true;
    }

    final fail = _selectedDevices
        .where((d) => d.status != '校验通过' && d.status != '校验超时')
        .length;
    final timeout = _selectedDevices
        .where((d) => d.status == '校验超时')
        .length;
    controller.setStepStatus(4, StepStatus.failed);
    controller.setSummary(
      t.selfUpdate.validFailedSummary(fail: fail, timeout: timeout),
    );
    controller.setPhase(UpdatePhase.validFailed);
    return false;
  }

  /// 校验失败后点击【重新校验】：清空校验结果、步骤 4 恢复 running，重新校验；
  /// 成功后继续进入写入。
  Future<void> reValid() async {
    _clearValidResults();
    controller.clearFailure(4);
    controller.setSummary('');
    if (await runValid()) {
      await runWrite();
    }
  }

  bool _allValidOk(List<ValidReply> replies) {
    final okKeys = replies
        .where((r) => r.ok)
        .map((r) => deviceKey(r.deviceType, r.ip))
        .toSet();
    return okKeys.containsAll(_deviceKeys);
  }

  void _markValidDevices(List<ValidReply> replies) {
    final replied = <String>{};
    for (final reply in replies) {
      replied.add(deviceKey(reply.deviceType, reply.ip));
      final device = _selectedDevices.where(
        (d) => d.rawIp == reply.ip && d.type == reply.deviceType,
      );
      if (device.isEmpty) {
        continue;
      }
      final target = device.first;
      if (reply.ok) {
        target.status = '校验通过';
        target.result = '';
        target.detail = '';
      } else {
        target.status = '校验失败';
        target.result = '校验失败';
        target.detail = selfUpdateFailReasonText(reply.reason ?? 'unknown');
      }
    }
    for (final device in _selectedDevices) {
      if (!replied.contains(deviceKey(device.type, device.rawIp))) {
        device.status = '校验超时';
        device.result = '校验超时';
        device.detail = '';
      }
    }
  }

  void _clearValidResults() {
    for (final device in _selectedDevices) {
      device.status = '';
      device.result = '';
    }
  }

  String _replyKey(UpdateReply reply) {
    if (reply is FileAckReply) {
      return deviceKey(reply.deviceType, reply.ip);
    }
    return '';
  }

  /// 写入阶段（步骤 5）：3 个独立 15 秒窗口广播 `write:<file头>`。
  ///
  /// 返回是否「全部目标设备都回 write_ok」；否则进入 writeFailed 可恢复失败态。
  /// 写入成功后进入步骤 6（update）的占位状态，暂不做任何等待。
  Future<bool> runWrite() async {
    controller.setActiveStep(5);
    controller.setStepStatus(5, StepStatus.running);

    final command = UpdateProtocol.encodeWrite(
      crc32: _fileCrc32,
      packetCount: _filePacketCount,
      totalBytes: _fileTotalBytes,
      fileName: _fileName,
    );

    var lastReplies = <WriteResultReply>[];
    for (var window = 0; window < UpdateSession.maxAttempts; window++) {
      _laterReplies.addAll(session.extractUpdateReplies());

      final replies = await session.collectUntil<WriteResultReply>(
        command: command,
        timeout: writeTimeout,
        attempts: 1,
        matches: (reply) => reply is WriteResultReply,
        isDone: (collected) {
          final okKeys = collected
              .where((r) => r.ok)
              .map((r) => deviceKey(r.deviceType, r.ip))
              .toSet();
          return okKeys.containsAll(_deviceKeys);
        },
      );
      lastReplies = replies;
      if (_allWriteOk(lastReplies)) {
        break;
      }
    }

    _markWriteDevices(lastReplies);

    if (_selectedDevices.every((d) => d.status == '写入成功')) {
      controller.setStepStatus(5, StepStatus.success);
      controller.setActiveStep(6);
      controller.setStepStatus(6, StepStatus.running);
      return true;
    }

    final fail = _selectedDevices
        .where((d) => d.status != '写入成功' && d.status != '写入超时')
        .length;
    final timeout = _selectedDevices
        .where((d) => d.status == '写入超时')
        .length;
    controller.setStepStatus(5, StepStatus.failed);
    controller.setSummary(
      t.selfUpdate.writeFailedSummary(fail: fail, timeout: timeout),
    );
    controller.setPhase(UpdatePhase.writeFailed);
    return false;
  }

  /// 写入失败后点击【重新写入】：清空写入结果、步骤 5 恢复 running，重新写入。
  Future<void> reWrite() async {
    _clearWriteResults();
    controller.clearFailure(5);
    controller.setSummary('');
    await runWrite();
  }

  bool _allWriteOk(List<WriteResultReply> replies) {
    final okKeys = replies
        .where((r) => r.ok)
        .map((r) => deviceKey(r.deviceType, r.ip))
        .toSet();
    return okKeys.containsAll(_deviceKeys);
  }

  void _markWriteDevices(List<WriteResultReply> replies) {
    final replied = <String>{};
    for (final reply in replies) {
      replied.add(deviceKey(reply.deviceType, reply.ip));
      final device = _selectedDevices.where(
        (d) => d.rawIp == reply.ip && d.type == reply.deviceType,
      );
      if (device.isEmpty) {
        continue;
      }
      final target = device.first;
      if (reply.ok) {
        target.status = '写入成功';
        target.result = '';
        target.detail = '';
      } else {
        target.status = '写入失败';
        target.result = '写入失败';
        target.detail = selfUpdateFailReasonText(reply.reason ?? 'unknown');
      }
    }
    for (final device in _selectedDevices) {
      if (!replied.contains(deviceKey(device.type, device.rawIp))) {
        device.status = '写入超时';
        device.result = '写入超时';
        device.detail = '';
      }
    }
  }


  /// 回执阶段（步骤 6）：write 成功后被动等待 30 秒，收集 `update_ok` / `update_fail`。
  ///
  /// 只有「写入成功」的设备会参与统计；`update_fail` 设备保持「更新失败」、
  /// 30 秒内未回的设备标记「回执超时」，最终进入 `finished` 并显示【关闭】。
  Future<void> runUpdate() async {
    controller.setActiveStep(6);
    controller.setStepStatus(6, StepStatus.running);

    // 先抽取 write 阶段各窗口期间提前到达的 update 回执，避免被后续窗口清掉。
    final cached = session.extractUpdateReplies();
    _laterReplies.addAll(cached);

    final writeOkKeys = _selectedDevices
        .where((d) => d.status == '写入成功')
        .map((d) => deviceKey(d.type, d.rawIp))
        .toSet();

    final received = await session.waitFor<UpdateResultReply>(
      timeout: receiptTimeout,
      matches: (reply) => reply is UpdateResultReply,
      isDone: (collected) {
        final keys = collected.map(_updateReplyKey).toSet();
        return writeOkKeys.isNotEmpty && keys.containsAll(writeOkKeys);
      },
    );

    // 合并缓存 + 新收；同设备连续发 3 次时保留第一条。
    final merged = <String, UpdateResultReply>{};
    for (final reply in _laterReplies.whereType<UpdateResultReply>()) {
      merged.putIfAbsent(_updateReplyKey(reply), () => reply);
    }
    for (final reply in received) {
      merged.putIfAbsent(_updateReplyKey(reply), () => reply);
    }

    _markUpdateDevices(writeOkKeys, merged.values.toList());

    var success = 0;
    var fail = 0;
    var timeout = 0;
    for (final device in _selectedDevices) {
      if (!writeOkKeys.contains(deviceKey(device.type, device.rawIp))) {
        continue;
      }
      if (device.status == '更新成功') {
        success++;
      } else if (device.status == '更新失败') {
        fail++;
      } else {
        timeout++;
      }
    }

    controller.setSummary(
      t.selfUpdate.updateCompletedSummary(
        success: success,
        fail: fail,
        timeout: timeout,
      ),
    );
    var allUpdated = true;
    for (final device in _selectedDevices) {
      final key = deviceKey(device.type, device.rawIp);
      if (writeOkKeys.contains(key) && device.status != '更新成功') {
        allUpdated = false;
        break;
      }
    }
    controller.setStepStatus(
      6,
      allUpdated ? StepStatus.success : StepStatus.failed,
    );
    controller.setPhase(UpdatePhase.finished);
  }

  String _updateReplyKey(UpdateResultReply reply) =>
      deviceKey(reply.deviceType, reply.ip);

  void _markUpdateDevices(
    Set<String> writeOkKeys,
    List<UpdateResultReply> replies,
  ) {
    final replied = <String>{};
    for (final reply in replies) {
      final key = deviceKey(reply.deviceType, reply.ip);
      replied.add(key);
      final device = _selectedDevices.where(
        (d) => d.rawIp == reply.ip && d.type == reply.deviceType,
      );
      if (device.isEmpty || !writeOkKeys.contains(key)) {
        continue;
      }
      final target = device.first;
      if (reply.ok) {
        target.status = '更新成功';
        target.result = '更新成功';
        target.detail = 'v${reply.detail}';
      } else {
        target.status = '更新失败';
        target.result = '回执失败';
        target.detail = selfUpdateFailReasonText(reply.detail);
      }
    }
    for (final device in _selectedDevices) {
      final key = deviceKey(device.type, device.rawIp);
      if (writeOkKeys.contains(key) && !replied.contains(key)) {
        device.status = '回执超时';
        device.result = '回执超时';
        device.detail = '';
      }
    }
  }

  void _clearWriteResults() {
    for (final device in _selectedDevices) {
      device.status = '';
      device.result = '';
    }
  }

  void _terminate(String summary) {
    _state = TransferState.cancelled;
    for (final device in _selectedDevices) {
      device.result = summary.contains('超时') ? '传输超时' : '传输失败';
      device.detail = summary;
    }
    controller.markFailed(controller.activeStep);
    controller.setSummary(summary);
    controller.setPhase(UpdatePhase.finished);
    controller.setTransferStage(TransferStage.finished);
    session.reset();
  }
}
