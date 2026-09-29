import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';

/// 分包阶段日志级别。
///
/// - [off]：默认，不打印每个分包/ACK 的详细字段，只保留 `file:` 与每 100 包进度摘要。
/// - [error]：只打印分包错误（`packet_fail`），静默 `packet:`/`packet_ok`。
/// - [full]：全量打印每个分包与 ACK。
enum PacketLogLevel { off, error, full }

/// 自更新协议控制台日志。
///
/// 把收/发码流按字段拆分打印：
///
/// ```
/// ==================== 发送 ============================
/// 总码流：0x..
/// 【字段中文名称】：值（N 个字节）
/// ...
/// ==================== 接收 - "IP地址" ============================
/// 总码流：0x..
/// 【字段中文名称】：值（N 个字节）
/// ```
///
/// `packet:` 的「分包数据」字段只打印前几个字节，避免 1400 字节载荷刷屏。
class UpdateProtocolLogger {
  UpdateProtocolLogger._();

  /// 分包阶段日志级别，UI/调试入口可随时切换。
  static PacketLogLevel packetLogLevel = PacketLogLevel.off;

  /// 最近一次 `file:` 指令声明的分包总数，用于 `packet:` 打印「第几包/总包数」。
  static int _totalPackets = 0;

  /// 打印一条下行（CPDS → CPDC）指令。
  static void logSend(Uint8List bytes) {
    if (_hasPrefix(bytes, UpdateProtocol.packetPrefix)) {
      switch (packetLogLevel) {
        case PacketLogLevel.off:
          _logPacketProgress(bytes);
          return;
        case PacketLogLevel.error:
          return;
        case PacketLogLevel.full:
          break;
      }
    }
    debugPrint(describe(bytes, outgoing: true));
  }

  /// 打印一条上行（CPDC → CPDS）回复。
  static void logReceive(Uint8List bytes, {String? sourceIp}) {
    if (_hasPrefix(bytes, UpdateProtocol.packetOkPrefix) ||
        _hasPrefix(bytes, UpdateProtocol.packetFailPrefix)) {
      switch (packetLogLevel) {
        case PacketLogLevel.off:
          return;
        case PacketLogLevel.error:
          if (_hasPrefix(bytes, UpdateProtocol.packetOkPrefix)) {
            return;
          }
          break;
        case PacketLogLevel.full:
          break;
      }
    }
    debugPrint(describe(bytes, outgoing: false, sourceIp: sourceIp));
  }

  /// off 模式下的分包进度摘要：每 100 包（及最后一包）打印一次。
  static void _logPacketProgress(Uint8List bytes) {
    const prefix = 'packet:';
    final packetNumber = _uint32(bytes, prefix.length + 4);
    if (packetNumber % 100 == 0 || packetNumber == _totalPackets) {
      debugPrint('分包 $packetNumber/$_totalPackets 已发送');
    }
  }

  /// 打印 UDP 打开连接日志。
  static void logOpen() {
    debugPrint(
      '===== [自更新][打开UDP连接] 监听 '
      '0.0.0.0:${UpdateProtocol.cpdsReceivePort}，'
      '发送 ${UpdateProtocol.cpdcReceivePort}（广播 255.255.255.255） =====',
    );
  }

  /// 打印 UDP 关闭连接日志。
  static void logClose() {
    debugPrint('===== [自更新][关闭UDP连接] =====');
  }

  /// 把字节转成 `0x0a, 0x0b` 形式的十六进制码流字符串；[limit] 非空时超长截断。
  static String _hex(List<int> bytes, {int? limit}) {
    if (bytes.isEmpty) {
      return '(空)';
    }
    final truncated = limit != null && bytes.length > limit;
    final shown = truncated ? bytes.sublist(0, limit) : bytes;
    final joined = shown
        .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
        .join(', ');
    return truncated ? '$joined, ...' : joined;
  }

  static int _uint16(Uint8List bytes, int offset) =>
      ByteData.sublistView(bytes).getUint16(offset, Endian.big);

  static int _uint32(Uint8List bytes, int offset) =>
      ByteData.sublistView(bytes).getUint32(offset, Endian.big);

  /// 单个字段行：`【label】：value（N 个字节）`。
  static String _field(String label, Object value, int byteCount) =>
      '【$label】：$value（$byteCount 个字节）';

  /// 读取 ID 字段，返回（类型，IP，下一个偏移）；解析失败返回 null。
  static (String, String, int)? _readId(Uint8List bytes, int offset) {
    if (offset + 2 > bytes.length) {
      return null;
    }
    final typeLen = _uint16(bytes, offset);
    offset += 2;
    if (offset + typeLen + 2 > bytes.length) {
      return null;
    }
    final type = utf8.decode(bytes.sublist(offset, offset + typeLen));
    offset += typeLen;

    final ipLen = _uint16(bytes, offset);
    offset += 2;
    if (offset + ipLen > bytes.length) {
      return null;
    }
    final ip = utf8.decode(bytes.sublist(offset, offset + ipLen));
    offset += ipLen;
    return (type, ip, offset);
  }

  /// 打印一条 ID 字段行：`【ID】：类型#IP（N 个字节）`。
  static void _appendId(List<String> lines, Uint8List bytes, int offset) {
    final id = _readId(bytes, offset);
    if (id == null) {
      return;
    }
    final totalBytes = id.$3 - offset;
    lines.add(_field('ID', '${id.$1}#${id.$2}', totalBytes));
  }

  /// 生成一条码流的完整描述。
  static String describe(
    Uint8List bytes, {
    required bool outgoing,
    String? sourceIp,
  }) {
    final lines = <String>[];
    if (outgoing) {
      lines.add('==================== 发送 ============================');
    } else {
      final ip = sourceIp ?? '';
      lines.add('==================== 接收 - "$ip" ============================');
    }
    // packet: 分包数据只打印前几个字节，总码流也只保留前缀 + 少量载荷，
    // 避免上千个分包把控制台刷爆。
    final truncateRaw =
        outgoing && _hasPrefix(bytes, UpdateProtocol.packetPrefix);
    lines.add('总码流：${_hex(bytes, limit: truncateRaw ? 64 : null)}');

    if (outgoing) {
      _describeOutgoing(bytes, lines);
    } else {
      _describeIncoming(bytes, lines);
    }
    return lines.join('\n');
  }

  static void _describeOutgoing(Uint8List bytes, List<String> lines) {
    final text = String.fromCharCodes(bytes);
    if (text == UpdateProtocol.scan) {
      _totalPackets = 0;
      lines.add(_field('指令', 'Scan', bytes.length));
      return;
    }
    if (text == UpdateProtocol.auth) {
      lines.add(_field('指令', 'auth', bytes.length));
      return;
    }
    if (_hasPrefix(bytes, '${UpdateProtocol.version}:')) {
      const prefix = 'version:';
      final targetRaw = bytes.sublist(prefix.length);
      lines.add(_field('指令', 'version:', prefix.length));
      lines.add(_field('目标版本号', utf8.decode(targetRaw), targetRaw.length));
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.filePrefix)) {
      _appendFileHeaderFields(
        lines,
        bytes,
        UpdateProtocol.filePrefix,
        updateTotalPackets: true,
      );
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.validPrefix)) {
      _appendFileHeaderFields(lines, bytes, UpdateProtocol.validPrefix);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.writePrefix)) {
      _appendFileHeaderFields(lines, bytes, UpdateProtocol.writePrefix);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.packetPrefix)) {
      const prefix = 'packet:';
      final offset = prefix.length;
      final crc = _uint32(bytes, offset);
      final packetNumber = _uint32(bytes, offset + 4);
      final packetLength = _uint32(bytes, offset + 8);
      final payload = bytes.sublist(offset + 12);
      lines.add(_field('指令', 'packet:', prefix.length));
      lines.add(_field('CRC32（本次分包）', crc, 4));
      lines.add(_field('包号', '$packetNumber/$_totalPackets', 4));
      lines.add(_field('分包长度', packetLength, 4));
      lines.add(_field('分包数据', _hex(payload, limit: 32), payload.length));
      return;
    }
    lines.add(_field('未知指令', String.fromCharCodes(bytes), bytes.length));
  }

  /// 打印 `file:` / `valid:` / `write:` 共用的 file 头字段。
  static void _appendFileHeaderFields(
    List<String> lines,
    Uint8List bytes,
    String prefix, {
    bool updateTotalPackets = false,
  }) {
    final offset = prefix.length;
    final crc = _uint32(bytes, offset);
    final packetCount = _uint32(bytes, offset + 4);
    final totalBytes = _uint32(bytes, offset + 8);
    final nameRaw = bytes.sublist(offset + 12);
    if (updateTotalPackets) {
      _totalPackets = packetCount;
    }
    lines.add(_field('指令', prefix, prefix.length));
    lines.add(_field('CRC32（整ZIP）', crc, 4));
    lines.add(_field('包数量', packetCount, 4));
    lines.add(_field('文件总字节', totalBytes, 4));
    lines.add(_field('文件名称', utf8.decode(nameRaw), nameRaw.length));
  }

  static void _describeIncoming(Uint8List bytes, List<String> lines) {
    if (_hasPrefix(bytes, UpdateProtocol.scanAck)) {
      lines.add(_field('指令', 'Scan:success', bytes.length));
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.authAckPrefix)) {
      lines.add(_field('指令', 'authAck:', 8));
      _appendId(lines, bytes, 8);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.versionOkPrefix)) {
      _prefixWithIdAndTail(lines, bytes, 'version_ok:', 11, '当前版本');
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.versionFailPrefix)) {
      _prefixWithIdAndTail(lines, bytes, 'version_fail:', 13, '原因');
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.fileAckPrefix)) {
      lines.add(_field('指令', 'fileAck:', 8));
      _appendId(lines, bytes, 8);
      _appendFileAckFields(lines, bytes);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.packetOkPrefix)) {
      _prefixWithIdAndPacketFields(lines, bytes, 'packet_ok:', 10);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.packetFailPrefix)) {
      _prefixWithIdAndPacketFields(lines, bytes, 'packet_fail:', 12);
      _appendTail(lines, bytes, '原因', 12);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.validOkPrefix)) {
      lines.add(_field('指令', 'valid_ok:', 9));
      _appendId(lines, bytes, 9);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.validFailPrefix)) {
      _prefixWithIdAndTail(lines, bytes, 'valid_fail:', 11, '原因');
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.writeOkPrefix)) {
      lines.add(_field('指令', 'write_ok:', 9));
      _appendId(lines, bytes, 9);
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.writeFailPrefix)) {
      _prefixWithIdAndTail(lines, bytes, 'write_fail:', 11, '原因');
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.updateOkPrefix)) {
      _prefixWithIdAndTail(lines, bytes, 'update_ok:', 10, '新版本');
      return;
    }
    if (_hasPrefix(bytes, UpdateProtocol.updateFailPrefix)) {
      _prefixWithIdAndTail(lines, bytes, 'update_fail:', 12, '原因');
      return;
    }
    lines.add(_field('未知回复', String.fromCharCodes(bytes), bytes.length));
  }

  /// 打印前缀 + ID + 一个变长尾部字段。
  static void _prefixWithIdAndTail(
    List<String> lines,
    Uint8List bytes,
    String prefix,
    int prefixLen,
    String tailLabel,
  ) {
    lines.add(_field('指令', prefix, prefixLen));
    _appendId(lines, bytes, prefixLen);
    final id = _readId(bytes, prefixLen);
    if (id == null) {
      return;
    }
    final tail = bytes.sublist(id.$3);
    lines.add(_field(tailLabel, utf8.decode(tail), tail.length));
  }

  /// 打印前缀 + ID + packet 附加字段（CRC32/包号/分包长度）。
  static void _prefixWithIdAndPacketFields(
    List<String> lines,
    Uint8List bytes,
    String prefix,
    int prefixLen,
  ) {
    lines.add(_field('指令', prefix, prefixLen));
    _appendId(lines, bytes, prefixLen);
    final id = _readId(bytes, prefixLen);
    if (id == null) {
      return;
    }
    final offset = id.$3;
    if (offset + 12 > bytes.length) {
      return;
    }
    lines.add(_field('CRC32（本次分包）', _uint32(bytes, offset), 4));
    lines.add(_field('包号', '${_uint32(bytes, offset + 4)}/$_totalPackets', 4));
    lines.add(_field('分包长度', _uint32(bytes, offset + 8), 4));
  }

  /// fileAck 中 ID 之后的 CRC32 / 包数量 / 文件总字节 / 文件名称。
  static void _appendFileAckFields(List<String> lines, Uint8List bytes) {
    final id = _readId(bytes, 8);
    if (id == null) {
      return;
    }
    final offset = id.$3;
    if (offset + 12 > bytes.length) {
      return;
    }
    lines.add(_field('CRC32（整ZIP）', _uint32(bytes, offset), 4));
    lines.add(_field('包数量', _uint32(bytes, offset + 4), 4));
    lines.add(_field('文件总字节', _uint32(bytes, offset + 8), 4));
    final nameRaw = bytes.sublist(offset + 12);
    lines.add(_field('文件名称', utf8.decode(nameRaw), nameRaw.length));
  }

  /// packet_fail 中分包长度之后的变长原因。
  static void _appendTail(
    List<String> lines,
    Uint8List bytes,
    String label,
    int prefixLen,
  ) {
    final id = _readId(bytes, prefixLen);
    if (id == null) {
      return;
    }
    final offset = id.$3 + 12;
    if (offset > bytes.length) {
      return;
    }
    final tail = bytes.sublist(offset);
    lines.add(_field(label, utf8.decode(tail), tail.length));
  }

  static bool _hasPrefix(Uint8List bytes, String prefix) {
    if (bytes.length < prefix.length) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix.codeUnitAt(i)) {
        return false;
      }
    }
    return true;
  }
}
