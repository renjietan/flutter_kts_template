import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';

class CpdsMessages {
  CpdsMessages._();

  static bool isZh(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'zh';

  static String errorCode(
    BuildContext context,
    CpdsErrorCode code, {
    Map<String, dynamic> params = const {},
  }) {
    final zh = isZh(context);
    switch (code) {
      case CpdsErrorCode.unspecified:
        return zh ? '未指定错误' : 'Unspecified error';
      case CpdsErrorCode.invalidMessage:
        return zh ? '消息格式无效' : 'Invalid message';
      case CpdsErrorCode.invalidPackage:
        return zh ? '通信包无效' : 'Invalid communication package';
      case CpdsErrorCode.packageTooLarge:
        return zh ? '通信包超过 1 MiB' : 'Package exceeds 1 MiB';
      case CpdsErrorCode.invalidZipSize:
        return zh ? 'ZIP 大小声明无效' : 'Invalid ZIP size declaration';
      case CpdsErrorCode.insufficientStorage:
        return zh ? '磁盘空间不足' : 'Insufficient storage';
      case CpdsErrorCode.authAssignmentConflict:
        return zh ? '认证分配冲突' : 'Authentication assignment conflict';
      case CpdsErrorCode.authConflict:
        return zh ? '认证绑定冲突' : 'Authentication binding conflict';
      case CpdsErrorCode.authBindingMissing:
        return zh ? '认证绑定不完整' : 'Authentication binding is incomplete';
      case CpdsErrorCode.busy:
        return zh ? '设备仍在处理上一会话' : 'Device is still processing the previous session';
      case CpdsErrorCode.fileSizeMismatch:
        return zh ? '文件大小不一致' : 'File size mismatch';
      case CpdsErrorCode.fileHashMismatch:
        return zh ? '文件哈希不一致' : 'File hash mismatch';
      case CpdsErrorCode.storageIoError:
        return zh ? '存储读写失败' : 'Storage I/O failed';
      case CpdsErrorCode.parseOutputFailed:
        return zh ? '解析输出失败' : 'Parse output failed';
      case CpdsErrorCode.parseTimeout:
        return zh ? '等待解析结果超时' : 'Timed out waiting for parse result';
      case CpdsErrorCode.outputWriteFailed:
        return zh ? '输出文件写入失败' : 'Output write failed';
      case CpdsErrorCode.skippedAfterPreviousFailure:
        return zh ? '因前序失败而跳过' : 'Skipped after an earlier failure';
      case CpdsErrorCode.sessionTimeout:
        return zh ? '会话超时' : 'Session timed out';
      case CpdsErrorCode.discoveryMismatch:
        return zh ? '发现设备类型或数量不匹配' : 'Discovered device types or counts do not match';
      case CpdsErrorCode.esnConflict:
        final instances = params['instances']?.toString() ?? '';
        return zh
            ? '发现重复 ESN（实例 $instances），请人工清空其中一台设备的 esn 字段后重试'
            : 'Duplicate ESN from instances $instances; manually clear the esn field on one device and retry';
      case CpdsErrorCode.authTimeout:
        return zh ? '认证回复超时' : 'Authentication response timed out';
      case CpdsErrorCode.transferSilenceTimeout:
        return zh ? '设备传输回复超时' : 'Device transfer response timed out';
      case CpdsErrorCode.transferNoProgress:
        return zh ? '设备传输长时间无进展' : 'Device transfer made no progress';
      case CpdsErrorCode.networkInterfaceError:
        return zh ? '业务有线网卡不可用' : 'Wired business interface is unavailable';
    }
  }

  static String failureStage(BuildContext context, String stage) {
    final zh = isZh(context);
    return switch (stage) {
      'DISCOVERY' => zh ? '发现' : 'Discovery',
      'AUTHENTICATION' => zh ? '认证' : 'Authentication',
      'TRANSFER' => zh ? '传输' : 'Transfer',
      'PARSE' => zh ? '解析' : 'Parse',
      _ => zh ? '系统' : 'System',
    };
  }

  static String deviceType(BuildContext context, CpdsDeviceType type) {
    final zh = isZh(context);
    return switch (type) {
      CpdsDeviceType.server => 'Server',
      CpdsDeviceType.hf => 'HF',
      CpdsDeviceType.multiBandRadio => 'MMR200',
      CpdsDeviceType.multiBandHandheld => 'PMR200',
      CpdsDeviceType.ccu => zh ? 'CCU-Main' : 'CCU-Main',
      CpdsDeviceType.ccuAudio => zh ? 'CCU-Audio' : 'CCU-Audio',
      CpdsDeviceType.iec => 'IEC',
      CpdsDeviceType.smallHandheld => zh ? 'Small Handheld' : 'Small Handheld',
      CpdsDeviceType.unspecified => zh ? '未知设备' : 'Unknown device',
    };
  }

  static String resultTitle(BuildContext context, CpdsActiveState state) {
    final zh = isZh(context);
    return switch (state) {
      CpdsActiveState.completed => zh ? '本次下发成功' : 'Distribution succeeded',
      CpdsActiveState.partialSuccess => zh
          ? '本次下发部分成功'
          : 'Distribution partially succeeded',
      _ => zh ? '本次下发失败' : 'Distribution failed',
    };
  }

  static String discoveryMismatchTitle(BuildContext context) =>
      isZh(context) ? '发现设备数量不匹配' : 'Discovered device count mismatch';

  static String discoveryMismatchPrompt(BuildContext context) =>
      isZh(context)
          ? '设备数量与发现设备数量不匹配，是否继续下发？'
          : 'The expected and discovered device counts do not match. Continue distribution?';

  static String restartPrompt(BuildContext context) =>
      isZh(context)
          ? '请重启通信参数下发成功的相关设备。'
          : 'Restart the devices that received the communication parameters successfully.';

  static String parameterTitle(BuildContext context) =>
      isZh(context) ? '错误参数' : 'Error parameters';

  static String noData(BuildContext context) =>
      isZh(context) ? '无数据' : 'No data';

  static String failureItem(
    BuildContext context,
    String stage,
    CpdsDeviceType type,
    String esn,
    String deviceId,
    CpdsErrorCode code,
    Map<String, dynamic> params,
  ) {
    final reason = errorCode(context, code, params: params);
    final stageText = failureStage(context, stage);
    final typeText = deviceType(context, type);
    final esnText = esn.isEmpty ? '--' : esn;
    final deviceText = deviceId.isEmpty ? '--' : deviceId;
    return '$stageText · $typeText · ESN $esnText · $deviceText · '
        '[${code.apiName}] $reason';
  }
}
