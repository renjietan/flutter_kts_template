import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';

class CpdsMessages {
  CpdsMessages._();

  static bool isZh(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'zh';

  static String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  static bool _isEastAr(BuildContext context) {
    final loc = Localizations.localeOf(context);
    return loc.languageCode == 'ar' && loc.countryCode == 'EG';
  }

  /// 三选一：中文 / 英文 / 阿拉伯语（东、西共用一套文案）。
  static String tr(BuildContext context, String zh, String en, String ar) {
    switch (_lang(context)) {
      case 'zh':
        return zh;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  /// 东阿拉伯（ar-EG）把 ASCII 数字转成东阿拉伯数字 ٠١٢٣٤٥٦٧٨٩。
  static String digits(BuildContext context, String s) {
    if (!_isEastAr(context)) return s;
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return s.replaceAllMapped(
      RegExp(r'[0-9]'),
      (m) => eastern[m.group(0)!.codeUnitAt(0) - 0x30],
    );
  }

  static String errorCode(
    BuildContext context,
    CpdsErrorCode code, {
    Map<String, dynamic> params = const {},
  }) {
    switch (code) {
      case CpdsErrorCode.unspecified:
        return tr(context, '未指定错误', 'Unspecified error', 'خطأ غير محدد');
      case CpdsErrorCode.invalidMessage:
        return tr(context, '消息格式无效', 'Invalid message', 'رسالة غير صالحة');
      case CpdsErrorCode.invalidPackage:
        return tr(context, '通信包无效', 'Invalid communication package', 'حزمة اتصال غير صالحة');
      case CpdsErrorCode.packageTooLarge:
        return digits(context, tr(context, '通信包超过 1 MiB', 'Package exceeds 1 MiB', 'تتجاوز حزمة الاتصال 1 MiB'));
      case CpdsErrorCode.invalidZipSize:
        return tr(context, 'ZIP 大小声明无效', 'Invalid ZIP size declaration', 'حجم ZIP المُعلن غير صالح');
      case CpdsErrorCode.insufficientStorage:
        return tr(context, '磁盘空间不足', 'Insufficient storage', 'مساحة التخزين غير كافية');
      case CpdsErrorCode.authAssignmentConflict:
        return tr(context, '认证分配冲突', 'Authentication assignment conflict', 'تعارض في تخصيص المصادقة');
      case CpdsErrorCode.authConflict:
        return tr(context, '认证绑定冲突', 'Authentication binding conflict', 'تعارض في ربط المصادقة');
      case CpdsErrorCode.authBindingMissing:
        return tr(context, '认证绑定不完整', 'Authentication binding is incomplete', 'ربط المصادقة غير مكتمل');
      case CpdsErrorCode.busy:
        return tr(context, '设备仍在处理上一会话', 'Device is still processing the previous session', 'الجهاز ما زال يعالج الجلسة السابقة');
      case CpdsErrorCode.fileSizeMismatch:
        return tr(context, '文件大小不一致', 'File size mismatch', 'عدم تطابق حجم الملف');
      case CpdsErrorCode.fileHashMismatch:
        return tr(context, '文件哈希不一致', 'File hash mismatch', 'عدم تطابق تجزئة الملف');
      case CpdsErrorCode.storageIoError:
        return tr(context, '存储读写失败', 'Storage I/O failed', 'فشل القراءة أو الكتابة في التخزين');
      case CpdsErrorCode.parseOutputFailed:
        return tr(context, '解析输出失败', 'Parse output failed', 'فشل إخراج التحليل');
      case CpdsErrorCode.parseTimeout:
        return tr(context, '等待解析结果超时', 'Timed out waiting for parse result', 'انتهت مهلة انتظار نتيجة التحليل');
      case CpdsErrorCode.outputWriteFailed:
        return tr(context, '输出文件写入失败', 'Output write failed', 'فشل كتابة ملف الإخراج');
      case CpdsErrorCode.skippedAfterPreviousFailure:
        return tr(context, '因前序失败而跳过', 'Skipped after an earlier failure', 'تم التخطي بسبب فشل سابق');
      case CpdsErrorCode.sessionTimeout:
        return tr(context, '会话超时', 'Session timed out', 'انتهت مهلة الجلسة');
      case CpdsErrorCode.discoveryMismatch:
        return tr(context, '发现设备类型或数量不匹配', 'Discovered device types or counts do not match', 'عدم تطابق أنواع أو عدد الأجهزة المكتشفة');
      case CpdsErrorCode.esnConflict:
        final instances = params['instances']?.toString() ?? '';
        return digits(context, tr(context,
            '发现重复 ESN（实例 $instances），请人工清空其中一台设备的 esn 字段后重试',
            'Duplicate ESN from instances $instances; manually clear the esn field on one device and retry',
            'تم اكتشاف ESN مكرر (المثيل $instances)، يرجى مسح حقل esn يدويًا على أحد الأجهزة والمحاولة مرة أخرى'));
      case CpdsErrorCode.authTimeout:
        return tr(context, '认证回复超时', 'Authentication response timed out', 'انتهت مهلة استجابة المصادقة');
      case CpdsErrorCode.transferSilenceTimeout:
        return tr(context, '设备传输回复超时', 'Device transfer response timed out', 'انتهت مهلة استجابة نقل الجهاز');
      case CpdsErrorCode.transferNoProgress:
        return tr(context, '设备传输长时间无进展', 'Device transfer made no progress', 'لم يُحرز نقل الجهاز أي تقدم');
      case CpdsErrorCode.networkInterfaceError:
        return tr(context, '业务有线网卡不可用', 'Wired business interface is unavailable', 'بطاقة الشبكة السلكية للأعمال غير متاحة');
    }
  }

  static String failureStage(BuildContext context, String stage) {
    return switch (stage) {
      'DISCOVERY' => tr(context, '发现', 'Discovery', 'الاكتشاف'),
      'AUTHENTICATION' => tr(context, '认证', 'Authentication', 'المصادقة'),
      'TRANSFER' => tr(context, '传输', 'Transfer', 'النقل'),
      'PARSE' => tr(context, '解析', 'Parse', 'التحليل'),
      _ => tr(context, '系统', 'System', 'النظام'),
    };
  }

  static String deviceType(BuildContext context, CpdsDeviceType type) {
    return switch (type) {
      CpdsDeviceType.server => 'Server',
      CpdsDeviceType.hf => 'HF',
      CpdsDeviceType.multiBandRadio => 'MMR200',
      CpdsDeviceType.multiBandHandheld => 'PMR200',
      CpdsDeviceType.ccu => 'CCU-Main',
      CpdsDeviceType.ccuAudio => 'CCU-Audio',
      CpdsDeviceType.vehInter => 'VehInter',
      CpdsDeviceType.iec => 'IEC',
      CpdsDeviceType.smallHandheld => 'Small Handheld',
      CpdsDeviceType.unspecified => tr(context, '未知设备', 'Unknown device', 'جهاز غير معروف'),
    };
  }

  static String resultTitle(BuildContext context, CpdsActiveState state) {
    return switch (state) {
      CpdsActiveState.completed => tr(context, '本次下发成功', 'Distribution succeeded', 'نجح التوزيع هذه المرة'),
      CpdsActiveState.partialSuccess => tr(context, '本次下发部分成功', 'Distribution partially succeeded', 'نجح التوزيع جزئيًا هذه المرة'),
      _ => tr(context, '本次下发失败', 'Distribution failed', 'فشل التوزيع هذه المرة'),
    };
  }

  static String discoveryMismatchTitle(BuildContext context) =>
      tr(context, '发现设备数量不匹配', 'Discovered device count mismatch', 'عدم تطابق عدد الأجهزة المكتشفة');

  static String discoveryMismatchPrompt(BuildContext context) =>
      tr(context,
          '设备数量与发现设备数量不匹配，是否继续下发？',
          'The expected and discovered device counts do not match. Continue distribution?',
          'عدد الأجهزة المتوقع لا يطابق عدد الأجهزة المكتشفة. هل تريد متابعة التوزيع؟');

  static String restartPrompt(BuildContext context) =>
      tr(context,
          '请重启通信参数下发成功的相关设备。',
          'Restart the devices that received the communication parameters successfully.',
          'يرجى إعادة تشغيل الأجهزة التي استلمت معلمات الاتصال بنجاح.');

  static String parameterTitle(BuildContext context) =>
      tr(context, '错误参数', 'Error parameters', 'معلمات خاطئة');

  static String noData(BuildContext context) =>
      tr(context, '无数据', 'No data', 'لا توجد بيانات');

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