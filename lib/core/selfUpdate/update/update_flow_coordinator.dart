import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';

/// 认证 + 版本校验 流程编排。
///
/// 依赖 [UpdateSession]（广播 + 超时重发）、[UpdateStepController]（UI 状态）、
/// [InstallPackageStorage]（读取 cpdc_config.json 的新版本）。
class UpdateFlowCoordinator {
  UpdateFlowCoordinator({
    required this.session,
    required this.controller,
    required this.storage,
    required this.baseName,
    required this.targetVersion,
    this.authTimeout = UpdateSession.authTimeout,
    this.versionTimeout = UpdateSession.versionTimeout,
  });

  final UpdateSession session;
  final UpdateStepController controller;
  final InstallPackageStorage storage;

  /// 解压后的安装文件夹名（install_yyyyMMdd_HHmmss），用于读取新版本。
  final String baseName;

  /// 目标版本号（上传时用户填写的 InstallPackageEntity.version）。
  final String targetVersion;

  final Duration authTimeout;
  final Duration versionTimeout;

  /// 无对应更新文件夹、不支持更新的设备类型。
  static const Set<String> unsupportedTypes = {
    'Server',
    'IEC',
    'SmallHandheld',
  };

  /// 认证 → 版本校验；任一阶段超时则终止并复位。
  Future<void> runAuthAndVersion() async {
    if (!await runAuth()) {
      _terminate('认证超时');
      return;
    }
    if (!await runVersionCheck()) {
      _terminate('版本校验超时');
    }
  }

  /// 认证：广播 "auth" 收集设备，插入表格（IP 重复标记）。
  Future<bool> runAuth() async {
    controller.setActiveStep(1);
    controller.setStepStatus(1, StepStatus.running);

    final replies = await session.collect<AuthAckReply>(
      command: UpdateProtocol.encodeAuth(),
      timeout: authTimeout,
      matches: (reply) => reply is AuthAckReply,
    );
    if (replies.isEmpty) {
      return false;
    }

    final seen = <String, int>{};
    for (final reply in replies) {
      if (unsupportedTypes.contains(reply.deviceType)) {
        continue;
      }
      final count = (seen[reply.ip] ?? 0) + 1;
      seen[reply.ip] = count;
      final displayIp = count > 1 ? '${reply.ip}（重复）' : reply.ip;
      controller.addDevice(
        UpdateDevice(
          ip: displayIp,
          type: reply.deviceType,
          rawIp: reply.ip,
        )..status = '认证成功',
      );
    }

    controller.setStepStatus(1, StepStatus.success);
    return true;
  }

  /// 版本校验：广播 "version:目标版本" 填充当前版本并比较，结束后暂停。
  Future<bool> runVersionCheck() async {
    controller.setActiveStep(2);
    controller.setStepStatus(2, StepStatus.running);

    final replies = await session.collect<UpdateReply>(
      command: UpdateProtocol.encodeVersion(targetVersion),
      timeout: versionTimeout,
      matches: (reply) => reply is VersionOkReply || reply is VersionFailReply,
    );
    if (replies.isEmpty) {
      return false;
    }

    // 新版本列 = 目标版本号。
    for (final device in controller.devices) {
      device.newVersion = targetVersion;
    }

    final repliedKeys = <String>{};
    for (final reply in replies.whereType<VersionOkReply>()) {
      repliedKeys.add('${reply.deviceType}#${reply.ip}');
      for (final device in controller.devices) {
        if (device.rawIp == reply.ip && device.type == reply.deviceType) {
          device.currentVersion = reply.version;
          device.status = device.currentVersion == targetVersion
              ? '已最新'
              : '需更新';
          break;
        }
      }
    }

    for (final reply in replies.whereType<VersionFailReply>()) {
      repliedKeys.add('${reply.deviceType}#${reply.ip}');
      for (final device in controller.devices) {
        if (device.rawIp == reply.ip && device.type == reply.deviceType) {
          device.status = '无法获取';
          device.result = '版本号格式非法';
          break;
        }
      }
    }

    // 超时未回的设备标记「无法获取」。
    for (final device in controller.devices) {
      if (!repliedKeys.contains('${device.type}#${device.rawIp}')) {
        device.status = '无法获取';
      }
    }

    controller.setStepStatus(2, StepStatus.success);
    controller.setPhase(UpdatePhase.paused);
    return true;
  }

  void _terminate(String summary) {
    controller.markFailed(controller.activeStep);
    controller.setSummary(summary);
    controller.setPhase(UpdatePhase.finished);
    session.reset();
  }
}
