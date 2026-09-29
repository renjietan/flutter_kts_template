import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/fail_reason_text.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

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

  /// 认证窗口数量：每个窗口独立广播收集一次，最多 3 次。
  static const int authWindows = 3;

  /// 版本校验窗口数量：每个窗口独立广播收集一次，最多 3 次。
  static const int versionWindows = 3;

  /// 认证 → 版本校验（首次进入步骤弹窗）。
  ///
  /// 认证失败时只进入可恢复失败态，不关闭 UDP、不复位会话。
  Future<void> runAuthAndVersion(int expectedDeviceCount) async {
    if (!await runAuth(expectedDeviceCount)) {
      return;
    }
    await runVersionCheck();
  }

  /// 认证失败后点击【重新认证】：清空设备表、认证步骤恢复进行中，
  /// 复用最初扫描数量重新发 `auth`（不重新扫描）。
  Future<void> reAuth(int expectedDeviceCount) async {
    controller.clearDevices();
    controller.clearFailure(1);
    if (!await runAuth(expectedDeviceCount)) {
      return;
    }
    controller.setPhase(UpdatePhase.running);
    await runVersionCheck();
  }

  /// 版本校验失败后点击【重新版本校验】：清空版本列、版本校验步骤恢复
  /// 进行中，复用已认证设备表（不重新认证、不重新扫描），重新执行 3 窗口校验。
  Future<void> reVersionCheck() async {
    _clearVersionColumns();
    controller.clearFailure(2);
    await runVersionCheck();
  }

  /// 认证：最多 [authWindows] 个独立窗口广播 `auth` 收集设备。
  ///
  /// 每个窗口独立收集并按「类型#IP」去重；当去重有效设备数达到
  /// [expectedDeviceCount]（扫描到的设备数）时立即成功，否则进入下一窗口。
  /// 3 个窗口后：
  /// - 最后一次窗口有效设备数 == 0 → 认证步骤标红 + 可恢复失败态。
  /// - 最后一次窗口有效设备数 > 0 → 认证步骤转绿，仍进入版本校验。
  Future<bool> runAuth(int expectedDeviceCount) async {
    controller.setActiveStep(1);
    controller.setStepStatus(1, StepStatus.running);

    var lastUnique = <AuthAckReply>[];
    for (var window = 0; window < authWindows; window++) {
      final replies = await session.collect<AuthAckReply>(
        command: UpdateProtocol.encodeAuth(),
        timeout: authTimeout,
        matches: (reply) => reply is AuthAckReply,
        attempts: 1,
      );
      lastUnique = _dedupeAuthReplies(replies);
      if (lastUnique.length >= expectedDeviceCount) {
        break;
      }
    }

    if (lastUnique.isEmpty) {
      controller.setStepStatus(1, StepStatus.failed);
      controller.setSummary(t.selfUpdate.authFailedCount(n: 0));
      controller.setPhase(UpdatePhase.authFailed);
      return false;
    }

    _populateDevices(lastUnique);
    controller.setStepStatus(1, StepStatus.success);
    return true;
  }

  /// 过滤不支持类型并按「类型#IP」去重。
  List<AuthAckReply> _dedupeAuthReplies(List<AuthAckReply> replies) {
    // 过滤不支持类型，并按「类型#IP」去重：同一设备多次回复只保留一次。
    final uniqueByKey = <String, AuthAckReply>{};
    for (final reply in replies) {
      if (unsupportedTypes.contains(reply.deviceType)) {
        continue;
      }
      uniqueByKey.putIfAbsent('${reply.deviceType}#${reply.ip}', () => reply);
    }
    return uniqueByKey.values.toList();
  }

  /// 把认证回复插入设备明细表，并在 IP 跨类型重复时标记「（重复）」。
  void _populateDevices(List<AuthAckReply> replies) {
    // 统计去重后各 IP 的出现次数，用于标记「IP（重复）」。
    final ipCount = <String, int>{};
    for (final reply in replies) {
      ipCount[reply.ip] = (ipCount[reply.ip] ?? 0) + 1;
    }

    for (final reply in replies) {
      final duplicatedIp = (ipCount[reply.ip] ?? 0) > 1;
      controller.addDevice(
        UpdateDevice(
          ip: duplicatedIp ? '${reply.ip}（重复）' : reply.ip,
          type: reply.deviceType,
          rawIp: reply.ip,
        )..status = '认证成功',
      );
    }
  }

  /// 版本校验：最多 [versionWindows] 个独立窗口广播 `version:<目标版本>`。
  ///
  /// 每个窗口独立收集 `version_ok`/`version_fail` 并按「类型#IP」去重；当
  /// 回复数达到 [controller.devices.length]（认证后设备表行数）时立即成功，
  /// 否则进入下一窗口。3 个窗口后：
  /// - 回复数 == 0 → 步骤标红 + 可恢复失败态（保留 UDP）。
  /// - 回复数 > 0 → 步骤转绿，填充版本，未回复设备标记「无法获取」。
  Future<bool> runVersionCheck() async {
    controller.setActiveStep(2);
    controller.setStepStatus(2, StepStatus.running);

    final expectedDeviceCount = controller.devices.length;
    var lastReplies = <UpdateReply>[];
    for (var window = 0; window < versionWindows; window++) {
      final replies = await session.collect<UpdateReply>(
        command: UpdateProtocol.encodeVersion(targetVersion),
        timeout: versionTimeout,
        matches: (reply) =>
            reply is VersionOkReply || reply is VersionFailReply,
        attempts: 1,
      );
      lastReplies = _dedupeVersionReplies(replies);
      if (lastReplies.length >= expectedDeviceCount) {
        break;
      }
    }

    if (lastReplies.isEmpty) {
      controller.setStepStatus(2, StepStatus.failed);
      controller.setSummary(t.selfUpdate.versionFailedCount(n: 0));
      controller.setPhase(UpdatePhase.versionFailed);
      return false;
    }

    _applyVersionReplies(lastReplies);
    controller.setStepStatus(2, StepStatus.success);
    controller.setActiveStep(3);
    controller.setTransferStage(TransferStage.notStarted);
    controller.setPhase(UpdatePhase.running);
    return true;
  }

  /// 按「类型#IP」去重版本回复（`version_ok`/`version_fail` 都携带 ID）。
  List<UpdateReply> _dedupeVersionReplies(List<UpdateReply> replies) {
    final uniqueByKey = <String, UpdateReply>{};
    for (final reply in replies) {
      if (reply is VersionOkReply) {
        uniqueByKey.putIfAbsent(
          '${reply.deviceType}#${reply.ip}',
          () => reply,
        );
      } else if (reply is VersionFailReply) {
        uniqueByKey.putIfAbsent(
          '${reply.deviceType}#${reply.ip}',
          () => reply,
        );
      }
    }
    return uniqueByKey.values.toList();
  }

  /// 把版本回复填充到设备表，未回复设备标记「无法获取」。
  void _applyVersionReplies(List<UpdateReply> replies) {
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
          device.result = selfUpdateFailReasonText(reply.reason);
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
  }

  /// 清空版本相关列，用于【重新版本校验】前复位。
  void _clearVersionColumns() {
    for (final device in controller.devices) {
      device.currentVersion = '';
      device.newVersion = '';
      device.status = '认证成功';
      device.result = '';
    }
  }

}
