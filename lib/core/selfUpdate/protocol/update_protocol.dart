import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// 自更新独立协议（与现有 cpd.proto 完全区分）。
///
/// 设备标识 ID = [类型字节长度 uint16BE] + [类型 UTF-8] + [IP字节长度 uint16BE] + [IP UTF-8]。
/// 所有 CPDC → CPDS 的上行回复（除 Scan:success）都携带 ID。
class UpdateProtocol {
  UpdateProtocol._();

  static const String scan = 'Scan';
  static const String scanAck = 'Scan:success';
  static const String auth = 'auth';
  static const String authAckPrefix = 'authAck:';
  static const String version = 'version';
  static const String versionOkPrefix = 'version_ok:';
  static const String versionFailPrefix = 'version_fail:';
  static const String filePrefix = 'file:';
  static const String fileAckPrefix = 'fileAck:';
  static const String packetPrefix = 'packet:';
  static const String packetOkPrefix = 'packet_ok:';
  static const String packetFailPrefix = 'packet_fail:';
  static const String validOkPrefix = 'valid_ok:';
  static const String validFailPrefix = 'valid_fail:';
  static const String updateOkPrefix = 'update_ok:';
  static const String updateFailPrefix = 'update_fail:';

  /// CPDC 监听的 UDP 端口（CPDS 向其广播命令）。
  static const int cpdcReceivePort = 39003;

  /// CPDS 监听的 UDP 端口（CPDC 向其回复）。
  static const int cpdsReceivePort = 39004;

  /// 单个 UDP 数据报最大字节数。
  static const int maxDatagramBytes = 1400;

  /// `"packet:"` + uint32BE CRC32 + uint32BE 包号 + uint32BE 长度 的固定头部字节数。
  static const int packetHeaderBytes = 7 + 4 + 4 + 4;

  /// 每个分包可承载的最大载荷字节数（使整包不超过 1400 字节）。
  static const int maxPacketPayloadBytes =
      maxDatagramBytes - packetHeaderBytes;

  /// 计算标准 CRC-32，返回无符号 32 位整数。
  static int crc32(List<int> bytes) => getCrc32(bytes) & 0xFFFFFFFF;

  /// 编码设备标识 ID。
  static Uint8List encodeId({
    required String deviceType,
    required String ip,
  }) {
    final typeBytes = utf8.encode(deviceType);
    final ipBytes = utf8.encode(ip);
    final data = Uint8List(2 + typeBytes.length + 2 + ipBytes.length);
    final view = ByteData.sublistView(data);
    view.setUint16(0, typeBytes.length, Endian.big);
    data.setRange(2, 2 + typeBytes.length, typeBytes);
    view.setUint16(2 + typeBytes.length, ipBytes.length, Endian.big);
    data.setRange(4 + typeBytes.length, data.length, ipBytes);
    return data;
  }

  // ---------------------------------------------------------------------------
  // 编码（CPDS → CPDC）
  // ---------------------------------------------------------------------------

  static Uint8List encodeScan() => Uint8List.fromList(utf8.encode(scan));

  static Uint8List encodeAuth() => Uint8List.fromList(utf8.encode(auth));

  static Uint8List encodeVersion(String versionNumber) =>
      Uint8List.fromList(utf8.encode('$version:$versionNumber'));

  /// `"file:"` + uint32BE CRC32 + uint32BE 包数量 + uint32BE 文件总字节 + 文件名。
  static Uint8List encodeFile({
    required int crc32,
    required int packetCount,
    required int totalBytes,
    required String fileName,
  }) {
    final prefix = utf8.encode(filePrefix);
    final nameBytes = utf8.encode(fileName);
    final data = Uint8List(prefix.length + 12 + nameBytes.length);
    data.setRange(0, prefix.length, prefix);
    final view = ByteData.sublistView(data);
    var offset = prefix.length;
    view.setUint32(offset, crc32 & 0xFFFFFFFF, Endian.big);
    offset += 4;
    view.setUint32(offset, packetCount, Endian.big);
    offset += 4;
    view.setUint32(offset, totalBytes, Endian.big);
    offset += 4;
    data.setRange(offset, data.length, nameBytes);
    return data;
  }

  /// `"packet:"` + uint32BE CRC32(本次分包) + uint32BE 包号 + uint32BE 分包长度 + 分包数据。
  static Uint8List encodePacket({
    required int crc32,
    required int packetNumber,
    required Uint8List payload,
  }) {
    final prefix = utf8.encode(packetPrefix);
    final data = Uint8List(prefix.length + 12 + payload.length);
    data.setRange(0, prefix.length, prefix);
    final view = ByteData.sublistView(data);
    var offset = prefix.length;
    view.setUint32(offset, crc32 & 0xFFFFFFFF, Endian.big);
    offset += 4;
    view.setUint32(offset, packetNumber, Endian.big);
    offset += 4;
    view.setUint32(offset, payload.length, Endian.big);
    offset += 4;
    data.setRange(offset, data.length, payload);
    return data;
  }

  /// 将数据按最大分包载荷拆成 `packet:` 指令列表（包号从 1 开始）。
  static List<Uint8List> splitPackets(Uint8List data) {
    final packets = <Uint8List>[];
    var packetNumber = 1;
    for (
      var offset = 0;
      offset < data.length;
      offset += maxPacketPayloadBytes
    ) {
      final end = (offset + maxPacketPayloadBytes < data.length)
          ? offset + maxPacketPayloadBytes
          : data.length;
      final payload = Uint8List.sublistView(data, offset, end);
      packets.add(
        encodePacket(
          crc32: crc32(payload),
          packetNumber: packetNumber,
          payload: payload,
        ),
      );
      packetNumber++;
    }
    return packets;
  }

  // ---------------------------------------------------------------------------
  // 解码回复（CPDC → CPDS）
  // ---------------------------------------------------------------------------

  static UpdateReply? parseReply(Uint8List bytes) {
    if (_startsWith(bytes, scanAck)) {
      return const ScanAckReply();
    }
    if (_startsWith(bytes, authAckPrefix)) {
      return _parseAuthAck(bytes);
    }
    if (_startsWith(bytes, versionOkPrefix)) {
      return _parseVersionOk(bytes);
    }
    if (_startsWith(bytes, versionFailPrefix)) {
      return _parseVersionFail(bytes);
    }
    if (_startsWith(bytes, fileAckPrefix)) {
      return _parseFileAck(bytes);
    }
    if (_startsWith(bytes, packetOkPrefix)) {
      return _parsePacketOk(bytes);
    }
    if (_startsWith(bytes, packetFailPrefix)) {
      return _parsePacketFail(bytes);
    }
    if (_startsWith(bytes, validOkPrefix)) {
      return _parseValidOk(bytes);
    }
    if (_startsWith(bytes, validFailPrefix)) {
      return _parseValidFail(bytes);
    }
    if (_startsWith(bytes, updateOkPrefix)) {
      return _parseUpdateOk(bytes);
    }
    if (_startsWith(bytes, updateFailPrefix)) {
      return _parseUpdateFail(bytes);
    }
    return null;
  }

  static AuthAckReply? _parseAuthAck(Uint8List bytes) {
    final id = _parseId(bytes, authAckPrefix.length);
    if (id == null || id.$3 != bytes.length) {
      return null;
    }
    return AuthAckReply(deviceType: id.$1, ip: id.$2);
  }

  static VersionOkReply? _parseVersionOk(Uint8List bytes) {
    final id = _parseId(bytes, versionOkPrefix.length);
    if (id == null) {
      return null;
    }
    final version = utf8.decode(bytes.sublist(id.$3));
    return VersionOkReply(deviceType: id.$1, ip: id.$2, version: version);
  }

  static VersionFailReply? _parseVersionFail(Uint8List bytes) {
    final id = _parseId(bytes, versionFailPrefix.length);
    if (id == null) {
      return null;
    }
    final reason = utf8.decode(bytes.sublist(id.$3));
    return VersionFailReply(deviceType: id.$1, ip: id.$2, reason: reason);
  }

  static FileAckReply? _parseFileAck(Uint8List bytes) {
    final id = _parseId(bytes, fileAckPrefix.length);
    if (id == null) {
      return null;
    }
    var offset = id.$3;
    if (offset + 12 > bytes.length) {
      return null;
    }
    final view = ByteData.sublistView(bytes);
    final crc32 = view.getUint32(offset, Endian.big);
    offset += 4;
    final packetCount = view.getUint32(offset, Endian.big);
    offset += 4;
    final totalBytes = view.getUint32(offset, Endian.big);
    offset += 4;
    final fileName = utf8.decode(bytes.sublist(offset));
    return FileAckReply(
      deviceType: id.$1,
      ip: id.$2,
      crc32: crc32,
      packetCount: packetCount,
      totalBytes: totalBytes,
      fileName: fileName,
    );
  }

  static PacketOkReply? _parsePacketOk(Uint8List bytes) {
    final id = _parseId(bytes, packetOkPrefix.length);
    if (id == null || id.$3 + 12 != bytes.length) {
      return null;
    }
    final view = ByteData.sublistView(bytes);
    var offset = id.$3;
    final crc32 = view.getUint32(offset, Endian.big);
    offset += 4;
    final packetNumber = view.getUint32(offset, Endian.big);
    offset += 4;
    final packetLength = view.getUint32(offset, Endian.big);
    return PacketOkReply(
      deviceType: id.$1,
      ip: id.$2,
      crc32: crc32,
      packetNumber: packetNumber,
      packetLength: packetLength,
    );
  }

  static PacketFailReply? _parsePacketFail(Uint8List bytes) {
    final id = _parseId(bytes, packetFailPrefix.length);
    if (id == null || id.$3 + 12 > bytes.length) {
      return null;
    }
    final view = ByteData.sublistView(bytes);
    var offset = id.$3;
    final crc32 = view.getUint32(offset, Endian.big);
    offset += 4;
    final packetNumber = view.getUint32(offset, Endian.big);
    offset += 4;
    final packetLength = view.getUint32(offset, Endian.big);
    offset += 4;
    final reason = utf8.decode(bytes.sublist(offset));
    return PacketFailReply(
      deviceType: id.$1,
      ip: id.$2,
      crc32: crc32,
      packetNumber: packetNumber,
      packetLength: packetLength,
      reason: reason,
    );
  }

  static ValidReply? _parseValidOk(Uint8List bytes) {
    final id = _parseId(bytes, validOkPrefix.length);
    if (id == null || id.$3 != bytes.length) {
      return null;
    }
    return ValidReply(deviceType: id.$1, ip: id.$2, ok: true);
  }

  static ValidReply? _parseValidFail(Uint8List bytes) {
    final id = _parseId(bytes, validFailPrefix.length);
    if (id == null) {
      return null;
    }
    final reason = utf8.decode(bytes.sublist(id.$3));
    return ValidReply(
      deviceType: id.$1,
      ip: id.$2,
      ok: false,
      reason: reason,
    );
  }

  static UpdateResultReply? _parseUpdateOk(Uint8List bytes) {
    final id = _parseId(bytes, updateOkPrefix.length);
    if (id == null) {
      return null;
    }
    final newVersion = utf8.decode(bytes.sublist(id.$3));
    return UpdateResultReply(
      ok: true,
      deviceType: id.$1,
      ip: id.$2,
      detail: newVersion,
    );
  }

  static UpdateResultReply? _parseUpdateFail(Uint8List bytes) {
    final id = _parseId(bytes, updateFailPrefix.length);
    if (id == null) {
      return null;
    }
    final reason = utf8.decode(bytes.sublist(id.$3));
    return UpdateResultReply(
      ok: false,
      deviceType: id.$1,
      ip: id.$2,
      detail: reason,
    );
  }

  static bool _startsWith(Uint8List bytes, String prefix) {
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

  static (String deviceType, String ip, int nextOffset)? _parseId(
    Uint8List bytes,
    int offset,
  ) {
    if (offset + 2 > bytes.length) {
      return null;
    }
    final typeLength = ByteData.sublistView(bytes).getUint16(offset, Endian.big);
    offset += 2;
    if (offset + typeLength + 2 > bytes.length) {
      return null;
    }
    final deviceType = utf8.decode(bytes.sublist(offset, offset + typeLength));
    offset += typeLength;
    final ipLength = ByteData.sublistView(bytes).getUint16(offset, Endian.big);
    offset += 2;
    if (offset + ipLength > bytes.length) {
      return null;
    }
    final ip = utf8.decode(bytes.sublist(offset, offset + ipLength));
    offset += ipLength;
    return (deviceType, ip, offset);
  }
}

/// 回复基类。
sealed class UpdateReply {
  const UpdateReply();
}

final class ScanAckReply extends UpdateReply {
  const ScanAckReply();
}

final class AuthAckReply extends UpdateReply {
  const AuthAckReply({required this.deviceType, required this.ip});

  final String deviceType;
  final String ip;
}

final class VersionOkReply extends UpdateReply {
  const VersionOkReply({
    required this.deviceType,
    required this.ip,
    required this.version,
  });

  final String deviceType;
  final String ip;
  final String version;
}

final class VersionFailReply extends UpdateReply {
  const VersionFailReply({
    required this.deviceType,
    required this.ip,
    required this.reason,
  });

  final String deviceType;
  final String ip;
  final String reason;
}

final class FileAckReply extends UpdateReply {
  const FileAckReply({
    required this.deviceType,
    required this.ip,
    required this.crc32,
    required this.packetCount,
    required this.totalBytes,
    required this.fileName,
  });

  final String deviceType;
  final String ip;
  final int crc32;
  final int packetCount;
  final int totalBytes;
  final String fileName;
}

final class PacketOkReply extends UpdateReply {
  const PacketOkReply({
    required this.deviceType,
    required this.ip,
    required this.crc32,
    required this.packetNumber,
    required this.packetLength,
  });

  final String deviceType;
  final String ip;
  final int crc32;
  final int packetNumber;
  final int packetLength;
}

final class PacketFailReply extends UpdateReply {
  const PacketFailReply({
    required this.deviceType,
    required this.ip,
    required this.crc32,
    required this.packetNumber,
    required this.packetLength,
    required this.reason,
  });

  final String deviceType;
  final String ip;
  final int crc32;
  final int packetNumber;
  final int packetLength;
  final String reason;
}

final class ValidReply extends UpdateReply {
  const ValidReply({
    required this.deviceType,
    required this.ip,
    required this.ok,
    this.reason,
  });

  final String deviceType;
  final String ip;
  final bool ok;
  final String? reason;
}

final class UpdateResultReply extends UpdateReply {
  const UpdateResultReply({
    required this.ok,
    required this.deviceType,
    required this.ip,
    required this.detail,
  });

  final bool ok;
  final String deviceType;
  final String ip;

  /// 成功时为新版本号，失败时为失败原因。
  final String detail;
}
