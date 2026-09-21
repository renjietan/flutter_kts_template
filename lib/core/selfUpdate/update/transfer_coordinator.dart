import 'dart:typed_data';

import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';

/// 设备标识键：类型#IP。
String deviceKey(String deviceType, String ip) => '$deviceType#$ip';

/// 将 update 阶段 fail 原因码翻译为当前语言文案；未知码原样返回。
String updateFailReasonText(String code) {
  final reasons = t.selfUpdate.failReason;
  switch (code) {
    case 'version_mismatch':
      return reasons.versionMismatch;
    case 'install_error':
      return reasons.installError;
    case 'restart_error':
      return reasons.restartError;
    case 'version_read_error':
      return reasons.versionReadError;
    default:
      return code;
  }
}

/// 传输 + 校验流程编排。
class TransferCoordinator {
  TransferCoordinator({
    required this.session,
    required this.controller,
    required this.storage,
    required this.baseName,
    this.transferTimeout = UpdateSession.transferTimeout,
    this.validTimeout = UpdateSession.validTimeout,
    this.receiptTimeout = const Duration(seconds: 30),
  });

  final UpdateSession session;
  final UpdateStepController controller;
  final InstallPackageStorage storage;
  final String baseName;
  final Duration transferTimeout;
  final Duration validTimeout;
  final Duration receiptTimeout;

  /// 执行传输（步骤 3）与校验（步骤 4）。
  ///
  /// 返回是否成功进入后续写入阶段。
  Future<bool> run(List<UpdateDevice> selectedDevices) async {
    if (selectedDevices.isEmpty) {
      return false;
    }

    final deviceKeys = selectedDevices
        .map((d) => deviceKey(d.type, d.rawIp))
        .toSet();

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
    final packets = UpdateProtocol.splitPackets(zipBytes);

    final fileCommand = UpdateProtocol.encodeFile(
      crc32: crc32,
      packetCount: packets.length,
      totalBytes: zipBytes.length,
      fileName: '$baseName.zip',
    );
    final fileOk = await _sendAndWaitAllAck(
      command: fileCommand,
      timeout: transferTimeout,
      matches: (reply) => reply is FileAckReply,
      deviceKeys: deviceKeys,
    );
    if (!fileOk) {
      _terminate('传输前置指令超时');
      return false;
    }

    for (final packet in packets) {
      final ok = await _sendPacketAndWaitAllAck(
        command: packet,
        deviceKeys: deviceKeys,
      );
      if (!ok) {
        _terminate('传输分包超时');
        return false;
      }
    }

    controller.setStepStatus(3, StepStatus.success);

    controller.setActiveStep(4);
    controller.setStepStatus(4, StepStatus.running);
    await _waitValid(selectedDevices, deviceKeys);
    controller.setStepStatus(4, StepStatus.success);
    controller.setPhase(UpdatePhase.paused);
    return true;
  }

  Future<bool> _sendAndWaitAllAck({
    required Uint8List command,
    required Duration timeout,
    required bool Function(UpdateReply reply) matches,
    required Set<String> deviceKeys,
  }) async {
    final acks = await session.collectUntil<UpdateReply>(
      command: command,
      timeout: timeout,
      matches: matches,
      isDone: (collected) {
        final keys = collected.map(_replyKey).toSet();
        return keys.containsAll(deviceKeys);
      },
    );
    final keys = acks.map(_replyKey).toSet();
    return keys.containsAll(deviceKeys);
  }

  /// 发送单个分包并等待所有设备 ACK；收到 packetError 或超时则重发。
  Future<bool> _sendPacketAndWaitAllAck({
    required Uint8List command,
    required Set<String> deviceKeys,
  }) async {
    for (var attempt = 0; attempt < UpdateSession.maxAttempts; attempt++) {
      final replies = await session.collectUntil<UpdateReply>(
        command: command,
        timeout: transferTimeout,
        attempts: 1,
        matches: (reply) => reply is PacketOkReply || reply is PacketFailReply,
        isDone: (collected) {
          final ackKeys = collected
              .whereType<PacketOkReply>()
              .map((r) => deviceKey(r.deviceType, r.ip))
              .toSet();
          final errorKeys = collected
              .whereType<PacketFailReply>()
              .map((r) => deviceKey(r.deviceType, r.ip))
              .toSet();
          return ackKeys.containsAll(deviceKeys) || errorKeys.isNotEmpty;
        },
      );
      final ackKeys = replies
          .whereType<PacketOkReply>()
          .map((r) => deviceKey(r.deviceType, r.ip))
          .toSet();
      final errorKeys = replies
          .whereType<PacketFailReply>()
          .map((r) => deviceKey(r.deviceType, r.ip))
          .toSet();
      if (ackKeys.containsAll(deviceKeys) && errorKeys.isEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _waitValid(
    List<UpdateDevice> selectedDevices,
    Set<String> deviceKeys,
  ) async {
    final validReplies = await session.waitFor<ValidReply>(
      timeout: validTimeout,
      matches: (reply) => reply is ValidReply,
      isDone: (collected) {
        final keys = collected.map((r) => deviceKey(r.deviceType, r.ip)).toSet();
        return keys.containsAll(deviceKeys);
      },
    );

    final replied = <String>{};
    for (final reply in validReplies) {
      replied.add(deviceKey(reply.deviceType, reply.ip));
      final device = selectedDevices.where(
        (d) => d.rawIp == reply.ip && d.type == reply.deviceType,
      );
      if (device.isEmpty) {
        continue;
      }
      final target = device.first;
      if (reply.ok) {
        target.status = '校验通过';
      } else {
        target.status = '校验失败: ${reply.reason ?? 'unknown'}';
      }
    }

    for (final device in selectedDevices) {
      if (!replied.contains(deviceKey(device.type, device.rawIp))) {
        device.status = '校验超时';
      }
    }
  }

  String _replyKey(UpdateReply reply) {
    if (reply is FileAckReply) {
      return deviceKey(reply.deviceType, reply.ip);
    }
    return '';
  }

  /// 写入（步骤 5）与回执（步骤 6）。
  ///
  /// 只有校验通过的设备才等待 update 回执；其余设备已在 valid 阶段标记失败/超时。
  Future<void> runReceipt(List<UpdateDevice> selectedDevices) async {
    controller.setActiveStep(5);
    controller.setStepStatus(5, StepStatus.running);
    controller.setStepStatus(5, StepStatus.success);

    controller.setActiveStep(6);
    controller.setStepStatus(6, StepStatus.running);

    final passedDevices = selectedDevices
        .where((d) => d.status == '校验通过')
        .toList();
    if (passedDevices.isEmpty) {
      _finishReceipt(selectedDevices, passedDevices);
      return;
    }

    final passedKeys = passedDevices
        .map((d) => deviceKey(d.type, d.rawIp))
        .toSet();
    final updateReplies = await session.waitFor<UpdateResultReply>(
      timeout: receiptTimeout,
      matches: (reply) => reply is UpdateResultReply,
      isDone: (collected) {
        final keys = collected
            .map((r) => deviceKey(r.deviceType, r.ip))
            .toSet();
        return keys.containsAll(passedKeys);
      },
    );

    for (final device in passedDevices) {
      final reply = updateReplies.where(
        (r) => r.deviceType == device.type && r.ip == device.rawIp,
      );
      if (reply.isEmpty) {
        device.status = '回执超时';
        device.result = '回执超时';
      } else if (reply.first.ok) {
        device.status = '更新成功';
        device.result = '成功(${reply.first.detail})';
      } else {
        device.status = '更新失败';
        device.result = '失败(${updateFailReasonText(reply.first.detail)})';
      }
    }

    _finishReceipt(selectedDevices, passedDevices);
  }

  void _finishReceipt(
    List<UpdateDevice> selectedDevices,
    List<UpdateDevice> passedDevices,
  ) {
    final ok = passedDevices.where((d) => d.status == '更新成功').length;
    final fail = passedDevices.where((d) => d.status == '更新失败').length;
    final timeout = passedDevices.where((d) => d.status == '回执超时').length;
    final skipped = selectedDevices.length - passedDevices.length;
    controller.setSummary(
      '更新完成：成功 $ok 台，失败 $fail 台，超时 $timeout 台，跳过 $skipped 台',
    );
    controller.setStepStatus(6, StepStatus.success);
    controller.setPhase(UpdatePhase.finished);
  }

  void _terminate(String summary) {
    controller.markFailed(controller.activeStep);
    controller.setSummary(summary);
    controller.setPhase(UpdatePhase.finished);
    session.reset();
  }
}
