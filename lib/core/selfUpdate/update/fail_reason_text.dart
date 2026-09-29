import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

/// 将协议 fail 原因码翻译为当前语言文案；未知码原样返回。
///
/// 原因码在协议上线传英文码，UI 侧依据当前工程语言（中/英/阿拉伯）翻译显示。
String selfUpdateFailReasonText(String code) {
  final reasons = t.selfUpdate.failReason;
  if (code.startsWith('missing_packet:')) {
    final packetNumbers = code.substring('missing_packet:'.length);
    return '${reasons.missingPacket} $packetNumbers';
  }
  if (code.startsWith('sequence:')) {
    final missing = code.substring('sequence:'.length);
    return reasons.sequence(n: missing);
  }
  final write = _writeFailReasonText(code);
  if (write != null) {
    return write;
  }
  switch (code) {
    case 'format':
      return reasons.format;
    case 'length':
      return reasons.length;
    case 'crc':
      return reasons.crc;
    case 'size':
      return reasons.size;
    case 'zip':
      return reasons.zip;
    case 'no_header':
      return reasons.noHeader;
    case 'mismatch':
      return reasons.mismatch;
    case 'install_error':
      return reasons.installError;
    case 'restart_error':
      return reasons.restartError;
    case 'restart_spawn_fail':
      return reasons.restartSpawnFail;
    case 'finalize_fail':
      return reasons.finalizeFail;
    case 'version_read_error':
      return reasons.versionReadError;
    case 'version_mismatch':
      return reasons.versionMismatch;
    default:
      return code;
  }
}

/// 解析 write_fail 的 `<码>`（可带 `<原因>`），翻译后拼接原因。
String? _writeFailReasonText(String code) {
  final colon = code.indexOf(':');
  final key = colon < 0 ? code : code.substring(0, colon);
  final detail = colon < 0 ? '' : code.substring(colon + 1);
  final text = _writeFailText(key);
  if (text == null) {
    return null;
  }
  return detail.isEmpty ? text : '$text：$detail';
}

String? _writeFailText(String key) {
  final r = t.selfUpdate.failReason;
  switch (key) {
    case 'unzip_fail':
      return r.unzipFail;
    case 'type_dir_not_found':
      return r.typeDirNotFound;
    case 'install_file_not_found':
      return r.installFileNotFound;
    case 'install_file_multiple':
      return r.installFileMultiple;
    case 'read_config_fail':
      return r.readConfigFail;
    case 'executable_path_fail':
      return r.executablePathFail;
    case 'overwrite_binary_open_fail':
      return r.overwriteBinaryOpenFail;
    case 'overwrite_binary_temp_fail':
      return r.overwriteBinaryTempFail;
    case 'overwrite_binary_rename_fail':
      return r.overwriteBinaryRenameFail;
    case 'overwrite_config_open_fail':
      return r.overwriteConfigOpenFail;
    case 'overwrite_config_temp_fail':
      return r.overwriteConfigTempFail;
    case 'overwrite_config_rename_fail':
      return r.overwriteConfigRenameFail;
    case 'overwrite_ini_open_fail':
      return r.overwriteIniOpenFail;
    case 'overwrite_ini_temp_fail':
      return r.overwriteIniTempFail;
    case 'overwrite_ini_rename_fail':
      return r.overwriteIniRenameFail;
    case 'write_marker_fail':
      return r.writeMarkerFail;
    case 'version_write_fail':
      return r.versionWriteFail;
    case 'empty_command':
      return r.emptyCommand;
    case 'mkdir_fail':
      return r.mkdirFail;
    case 'write_script_fail':
      return r.writeScriptFail;
    case 'write_params_fail':
      return r.writeParamsFail;
    default:
      return null;
  }
}
