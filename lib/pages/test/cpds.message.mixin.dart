import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO/socket.io.manager.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/test/cpds_right_panel.dart';

/// CPDS 消息发送 mixin。
///
/// 只负责 CPDS -> CPDC 的协议流程：
/// 发现（DISCOVER_NTY）、认证（AUTH_NTY）、传输（TRANSFER_START/CHUNK/END）
/// 以及解析结果确认（PARSE_COMPLETE_ACK）。
///
/// 依赖宿主页面提供 [deviceGroups]、[networkOptions]、[dataPath] 和
/// [sourceArchivePath]。这里没有生成 `cpd.proto` 的 Dart 类，因此先用手写的
/// Proto3 wire-format 编解码器实现必需消息；真实联调时把 [CpdProtoWriter]
/// 替换为生成的 `cpd.pb.dart` 即可。
mixin CpdsMessageMixin<T extends StatefulWidget> on State<T> {
  static const String broadcastAddress = '255.255.255.255';
  static const String loopbackAddress = '127.0.0.1';

  // CPDS 固定接收端口，CPDC 固定接收端口。
  static const int cpdsReceivePort = 39002;
  static const int cpdcReceivePort = 39001;

  // 协议时间参数，来源 03 文档 2.3。
  static const Duration discoverWindow = Duration(seconds: 5);
  static const Duration discoverInterval = Duration(seconds: 1);
  static const Duration authWindow = Duration(seconds: 5);
  static const Duration authRetryInterval = Duration(seconds: 1);

  final SocketIOManager _socketManager = SocketIOManager();
  StreamSubscription<RtcReceive>? _receiveSubscription;
  bool _sessionRunning = false;

  Uint8List _sessionId = Uint8List(16);
  final Map<String, CpdsDiscoveredDevice> _discoveredDevices = {};
  int _onlineCount = 0;

  int get onlineCount => _onlineCount;

  /// 当前节点已解析出的期望设备分组。
  List<CpdsDeviceGroup> get deviceGroups;

  /// 当前节点 ID，例如 `nn_vehicle_1001010000`。
  String get currentNodeId;

  /// 当前解析目录（ZIP 解压后的业务目录）。
  String get dataPath;

  /// 原始通信包 ZIP 路径。缺失时传输阶段只发送空占位包，用于联调日志。
  String? get sourceArchivePath;

  /// 是否已在发现阶段 / 下发流程中。
  bool get isDistributionRunning => _sessionRunning;

  void _updateOnlineCount(int count) {
    if (!mounted) {
      return;
    }
    setState(() {
      _onlineCount = count;
    });
  }

  void _updateDeviceStatus(
    CpdsDeviceType type, {
    String? esn,
    String? ip,
    CpdsDeviceStatus? status,
  }) {
    if (!mounted) {
      return;
    }

    final groups = deviceGroups
        .map(
          (group) => CpdsDeviceGroup(
            title: group.title,
            items: group.items.map((item) {
              if (CpdsDeviceType.fromLabel(item.typeLabel) != type) {
                return item;
              }
              final suffix = esn == null || esn.length < 6
                  ? item.esnSuffix
                  : esn.substring(esn.length - 6);
              return CpdsDeviceItem(
                typeLabel: item.typeLabel,
                model: item.model,
                esnSuffix: suffix,
                ip: ip ?? item.ip,
                status: status ?? item.status,
                progress: item.progress,
                statusText: item.statusText,
              );
            }).toList(),
          ),
        )
        .toList();

    setState(() {
      // 页面持有 deviceGroups 的地方应通过替换列表刷新。这里返回一个新的
      // 分组列表，宿主页面用 [onDeviceGroupsChanged] 同步到自己的状态。
      onDeviceGroupsChanged(groups);
    });
  }

  /// 由宿主页面实现：把 mixin 生成的设备分组列表回写到页面状态。
  void onDeviceGroupsChanged(List<CpdsDeviceGroup> groups);

  /// 开始发现 + 下发。
  Future<void> startDistribution() async {
    if (_sessionRunning) {
      return;
    }

    _sessionRunning = true;
    _sessionId = _randomUuid();
    _discoveredDevices.clear();
    _updateOnlineCount(0);

    _socketManager.configure(
      localPort: cpdsReceivePort,
      remotePort: cpdcReceivePort,
    );
    await _socketManager.init('');

    _receiveSubscription?.cancel();
    _receiveSubscription = _socketManager.receiveStream.listen(
      _handleDatagram,
      onError: (Object error) {
        GlobalLogger.logError('CPDS receive error: $error');
      },
    );

    await _runDiscovery();
    if (!_sessionRunning) {
      return;
    }

    final mismatch = _discoveryMismatch;
    if (mismatch != null) {
      final confirmed = await onDiscoveryMismatch(mismatch);
      if (!confirmed) {
        await _finishSession(success: false);
        return;
      }
    }

    await _runAuthentication();
    if (!_sessionRunning) {
      return;
    }

    await _runTransfer();
    if (!_sessionRunning) {
      return;
    }

    // 真实设备会在这段时间内上报 PARSE_COMPLETE_REQ。这里等待一个占位窗口。
    await Future<void>.delayed(const Duration(seconds: 1));
    _finishSession(success: true);
  }

  Future<void> cancelDistribution() async {
    if (!_sessionRunning) {
      return;
    }
    await _finishSession(success: false);
  }

  Future<void> _runDiscovery() async {
    final messageId = _randomUuid();

    for (var second = 0; second < discoverWindow.inSeconds; second++) {
      if (!_sessionRunning) {
        return;
      }
      _sendPacket(
        CpdProtoWriter.packet(
          sessionId: _sessionId,
          messageId: messageId,
          bodyField: 3,
          body: <int, dynamic>{},
        ),
      );
      await Future<void>.delayed(discoverInterval);
    }
  }

  Future<void> _runAuthentication() async {
    final assignments = _buildAuthAssignments();
    if (assignments.isEmpty) {
      await _finishSession(success: false);
      return;
    }

    for (var second = 0; second < authWindow.inSeconds; second++) {
      if (!_sessionRunning) {
        return;
      }
      for (final assignment in assignments) {
        final body = <int, dynamic>{
          1: <int, dynamic>{
            1: assignment.$1.value,
            2: assignment.$2,
            3: currentNodeId,
            4: assignment.$3,
          },
        };
        _sendPacket(
          CpdProtoWriter.packet(
            sessionId: _sessionId,
            messageId: _randomUuid(),
            bodyField: 5,
            body: body,
          ),
        );
      }
      await Future<void>.delayed(authRetryInterval);
    }
  }

  Future<void> _runTransfer() async {
    final archiveFile = sourceArchivePath == null
        ? null
        : File(sourceArchivePath!);
    Uint8List bytes;
    String fileName;

    if (archiveFile != null && archiveFile.existsSync()) {
      bytes = archiveFile.readAsBytesSync();
      fileName = archiveFile.uri.pathSegments.last;
    } else {
      // 联调占位：没有源 ZIP 时发送一个固定的小包。
      bytes = Uint8List.fromList('cpds-placeholder-package'.codeUnits);
      fileName = 'cpds_placeholder.zip';
    }

    final digest = sha256.convert(bytes).bytes;
    final chunks = _chunkBytes(bytes, chunkSize: 1200);

    // 首部 START x2。
    final startBody = <int, dynamic>{
      1: fileName,
      2: bytes.length,
      3: digest,
      4: bytes.length,
      5: bytes.length * 2,
      6: 1200,
      7: chunks.length,
    };
    final startMessage = CpdProtoWriter.packet(
      sessionId: _sessionId,
      messageId: _randomUuid(),
      bodyField: 7,
      body: startBody,
    );
    _sendPacket(startMessage);
    _sendPacket(startMessage);

    for (var index = 0; index < chunks.length; index++) {
      if (!_sessionRunning) {
        return;
      }
      final chunk = chunks[index];
      _sendPacket(
        CpdProtoWriter.packet(
          sessionId: _sessionId,
          messageId: _randomUuid(),
          bodyField: 8,
          body: <int, dynamic>{
            1: index,
            2: chunk,
            3: _crc32(chunk),
          },
        ),
      );
      // 1 Mbit/s 节流的占位实现：1200 字节约需 9.6ms，这里按 chunk 间隔近似。
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    // 尾部 START x2 + END。
    _sendPacket(startMessage);
    _sendPacket(startMessage);
    _sendPacket(
      CpdProtoWriter.packet(
        sessionId: _sessionId,
        messageId: _randomUuid(),
        bodyField: 10,
        body: <int, dynamic>{},
      ),
    );
  }

  Future<void> _finishSession({required bool success}) async {
    if (!_sessionRunning) {
      return;
    }
    _sessionRunning = false;
    await _receiveSubscription?.cancel();
    _receiveSubscription = null;
    await _socketManager.disconnect();
    if (mounted) {
      setState(() {});
    }
  }

  void _handleDatagram(RtcReceive receive) {
    if (!_sessionRunning) {
      return;
    }
    if (receive.data.length < 4 || !_validMagic(receive.data)) {
      return;
    }

    try {
      final packet = CpdProtoReader.readPacket(
        Uint8List.sublistView(receive.data, 4),
      );
      final bodyField = packet.bodyField;
      final body = packet.body;

      if (bodyField == 4) {
        _handleDiscoverResponse(body);
      } else if (bodyField == 6) {
        _handleAuthResponse(body);
      } else if (bodyField == 12) {
        _handleParseComplete(body);
      }
    } catch (error) {
      GlobalLogger.logError('CPDS 协议解析失败: $error');
    }
  }

  void _handleDiscoverResponse(Map<int, dynamic> body) {
    final esn = (body[1] as Uint8List?) ?? Uint8List(0);
    final ip = (body[4] as Uint8List?) ?? Uint8List(0);
    final esnText = String.fromCharCodes(esn);
    final ipText = String.fromCharCodes(ip);

    final rawTypes = body[3];
    final types = rawTypes is List<dynamic> ? rawTypes : <dynamic>[rawTypes];

    for (final rawType in types) {
      final type = CpdsDeviceType.fromValue(rawType as int? ?? 0);
      _discoveredDevices[esnText] = CpdsDiscoveredDevice(
        esn: esnText,
        ip: ipText,
        types: {type},
      );
      _updateDeviceStatus(
        type,
        esn: esnText,
        ip: ipText,
        status: CpdsDeviceStatus.discovered,
      );
    }
    _updateOnlineCount(_discoveredDevices.length);
  }

  void _handleAuthResponse(Map<int, dynamic> body) {
    // body[2] 为 result，0/1 表示成功/失败。
    final result = body[2] as int? ?? 0;
    if (result != 1) {
      _finishSession(success: false);
    }
  }

  void _handleParseComplete(Map<int, dynamic> body) {
    // 收到 PARSE_COMPLETE_REQ 后应回 PARSE_COMPLETE_ACK。
    // 这里仅保持 ACK 幂等，真实联调时根据 body[1] 的 ESN 和类型回包。
    _sendPacket(
      CpdProtoWriter.packet(
        sessionId: _sessionId,
        messageId: _randomUuid(),
        bodyField: 14,
        body: <int, dynamic>{},
      ),
    );
  }

  List<(CpdsDeviceType, String, String)> _buildAuthAssignments() {
    final result = <(CpdsDeviceType, String, String)>[];
    for (final group in deviceGroups) {
      for (final item in group.items) {
        final type = CpdsDeviceType.fromLabel(item.typeLabel);
        if (type == CpdsDeviceType.unknown) {
          continue;
        }
        final discovered = _discoveredDevices.values
            .where((device) => device.types.contains(type))
            .toList()
          ..sort((a, b) => a.esn.compareTo(b.esn));
        if (discovered.isEmpty) {
          continue;
        }
        result.add((type, discovered.first.esn, item.typeLabel));
      }
    }
    return result;
  }

  Map<String, int>? get _discoveryMismatch {
    final expected = <CpdsDeviceType, int>{};
    for (final group in deviceGroups) {
      for (final item in group.items) {
        final type = CpdsDeviceType.fromLabel(item.typeLabel);
        if (type == CpdsDeviceType.unknown) {
          continue;
        }
        expected[type] = (expected[type] ?? 0) + 1;
      }
    }

    final discovered = <CpdsDeviceType, int>{};
    for (final device in _discoveredDevices.values) {
      for (final type in device.types) {
        discovered[type] = (discovered[type] ?? 0) + 1;
      }
    }

    final diff = <String, int>{};
    for (final type in {...expected.keys, ...discovered.keys}) {
      final exp = expected[type] ?? 0;
      final got = discovered[type] ?? 0;
      if (exp != got) {
        diff[type.label] = exp - got;
      }
    }
    return diff.isEmpty ? null : diff;
  }

  Future<bool> onDiscoveryMismatch(Map<String, int> mismatch) async {
    // 默认不允许继续；宿主页面可覆盖为弹窗确认。
    return false;
  }

  void _sendPacket(Uint8List packet) {
    if (packet.length > 1400) {
      GlobalLogger.logError('CPDS 消息超过 1400 字节，已拒绝发送');
      return;
    }
    final frame = CpdProtoWriter.frame(packet);
    _socketManager.write(frame, broadcastAddress);
    _socketManager.write(frame, loopbackAddress);
  }

  static bool _validMagic(Uint8List data) {
    return data[0] == 0xEE &&
        data[1] == 0xDD &&
        data[2] == 0xCC &&
        data[3] == 0xBB;
  }

  static Uint8List _randomUuid() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    return bytes;
  }

  static List<Uint8List> _chunkBytes(
    Uint8List data, {
    int chunkSize = 1200,
  }) {
    final chunks = <Uint8List>[];
    for (var index = 0; index < data.length; index += chunkSize) {
      final end = min(index + chunkSize, data.length);
      chunks.add(Uint8List.sublistView(data, index, end));
    }
    return chunks;
  }

  static int _crc32(Uint8List data) {
    // 简化 CRC32/IEEE，仅供占位。正式实现请使用 archive 或 crc32 包的
    // CRC32/IEEE 实现。
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }

  @override
  void dispose() {
    _receiveSubscription?.cancel();
    _socketManager.disconnect();
    super.dispose();
  }
}

enum CpdsDeviceType {
  unspecified(0, '未指定'),
  ccu(1, 'CCU'),
  server(2, 'Server'),
  iec(3, 'IEC'),
  multiBandRadio(4, 'MMR200'),
  multibandHandheld(5, 'PMR200'),
  hf(6, 'MR9360'),
  smallHandheld(7, 'PRR206'),
  ccuAudio(8, 'CCU-Audio'),
  unknown(999, '未知');

  const CpdsDeviceType(this.value, this.label);

  final int value;
  final String label;

  static CpdsDeviceType fromValue(int value) {
    for (final type in values) {
      if (type.value == value) {
        return type;
      }
    }
    return unknown;
  }

  static CpdsDeviceType fromLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.startsWith('dc_ccu_')) {
      return ccu;
    }
    if (normalized.startsWith('dc_server_')) {
      return server;
    }
    if (normalized.startsWith('dc_iec_')) {
      return iec;
    }
    if (normalized.startsWith('dc_mmr200_') ||
        normalized.contains('mmr200')) {
      return multiBandRadio;
    }
    if (normalized.startsWith('dc_pmr200_') ||
        normalized.contains('pmr200')) {
      return multibandHandheld;
    }
    if (normalized.startsWith('dc_mr9360_') ||
        normalized.contains('mr9360')) {
      return hf;
    }
    if (normalized.startsWith('dc_prr206_') ||
        normalized.contains('prr206')) {
      return smallHandheld;
    }
    if (normalized.contains('ccu-audio') || normalized.contains('ccu_audio')) {
      return ccuAudio;
    }
    if (normalized.contains('ccu')) {
      return ccu;
    }
    if (normalized.contains('server')) {
      return server;
    }
    if (normalized.contains('iec')) {
      return iec;
    }
    if (normalized.contains('hf') || normalized.contains('small handheld')) {
      return normalized.contains('small handheld') ? smallHandheld : hf;
    }
    return unknown;
  }
}

class CpdsDiscoveredDevice {
  CpdsDiscoveredDevice({
    required this.esn,
    required this.ip,
    required this.types,
  });

  final String esn;
  final String ip;
  final Set<CpdsDeviceType> types;
}

/// 最小的 Proto3 wire-format 写入器，用于构造 CPDS 出站消息。
///
/// 字段号与 `cpd.proto` 保持一致：
/// - Packet: session_id=1, message_id=2, oneof body=3..14
/// - DISCOVER_NTY=3, DISCOVER_RSP=4, AUTH_NTY=5, AUTH_RSP=6,
///   TRANSFER_START_NTY=7, TRANSFER_CHUNK_NTY=8, TRANSFER_PROGRESS_RSP=9,
///   TRANSFER_END_NTY=10, TRANSFER_LOSSPACK_REQ=11, TRANSFER_COMPLETE_RSP=12,
///   PARSE_COMPLETE_REQ=13, PARSE_COMPLETE_ACK=14。
class CpdProtoWriter {
  static Uint8List frame(Uint8List packet) {
    final bytes = BytesBuilder();
    bytes.add(<int>[0xEE, 0xDD, 0xCC, 0xBB]);
    bytes.add(packet);
    return bytes.takeBytes();
  }

  static Uint8List packet({
    required Uint8List sessionId,
    required Uint8List messageId,
    required int bodyField,
    required Map<int, dynamic> body,
  }) {
    final writer = _ProtoWriter();
    writer.writeBytes(1, sessionId);
    writer.writeBytes(2, messageId);
    writer.writeLengthDelimited(bodyField, encode(body));
    return writer.takeBytes();
  }

  static Uint8List encode(Map<int, dynamic> fields) {
    final writer = _ProtoWriter();
    for (final entry in fields.entries) {
      _writeValue(writer, entry.key, entry.value);
    }
    return writer.takeBytes();
  }

  static void _writeValue(_ProtoWriter writer, int field, dynamic value) {
    if (value is int) {
      writer.writeVarint(field, value);
    } else if (value is String) {
      writer.writeBytes(field, Uint8List.fromList(value.codeUnits));
    } else if (value is Uint8List) {
      writer.writeBytes(field, value);
    } else if (value is List<dynamic>) {
      for (final item in value) {
        _writeValue(writer, field, item);
      }
    } else if (value is Map<int, dynamic>) {
      writer.writeLengthDelimited(field, encode(value));
    }
  }
}

class CpdProtoReader {
  static CpdPacket readPacket(Uint8List data) {
    final fields = _parseFields(data);
    final sessionId = fields[1] as Uint8List? ?? Uint8List(0);
    final messageId = fields[2] as Uint8List? ?? Uint8List(0);
    int bodyField = 0;
    Map<int, dynamic> body = <int, dynamic>{};
    for (final field in fields.keys) {
      if (field >= 3 && field <= 14) {
        bodyField = field;
        final raw = fields[field];
        body = raw is Uint8List ? _parseFields(raw) : <int, dynamic>{};
        break;
      }
    }
    return CpdPacket(
      sessionId: sessionId,
      messageId: messageId,
      bodyField: bodyField,
      body: body,
    );
  }

  static Map<int, dynamic> _parseFields(Uint8List data) {
    final result = <int, dynamic>{};
    var offset = 0;
    while (offset < data.length) {
      final key = _readVarint(data, offset);
      final field = key.$1 >> 3;
      final wireType = key.$1 & 0x07;
      offset = key.$2;
      if (wireType == 0) {
        final value = _readVarint(data, offset);
        _addFieldValue(result, field, value.$1);
        offset = value.$2;
      } else if (wireType == 2) {
        final length = _readVarint(data, offset);
        offset = length.$2;
        final value = Uint8List.sublistView(
          data,
          offset,
          offset + length.$1,
        );
        offset += length.$1;
        _addFieldValue(result, field, value);
      } else {
        break;
      }
    }
    return result;
  }

  static void _addFieldValue(
    Map<int, dynamic> result,
    int field,
    dynamic value,
  ) {
    final existing = result[field];
    if (existing == null) {
      result[field] = value;
    } else if (existing is List<dynamic>) {
      existing.add(value);
    } else {
      result[field] = <dynamic>[existing, value];
    }
  }

  static (int, int) _readVarint(Uint8List data, int offset) {
    var result = 0;
    var shift = 0;
    while (offset < data.length) {
      final byte = data[offset++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return (result, offset);
  }
}

class CpdPacket {
  const CpdPacket({
    required this.sessionId,
    required this.messageId,
    required this.bodyField,
    required this.body,
  });

  final Uint8List sessionId;
  final Uint8List messageId;
  final int bodyField;
  final Map<int, dynamic> body;
}

class _ProtoWriter {
  final BytesBuilder _builder = BytesBuilder();

  void writeVarint(int field, int value) {
    _writeKey(field, 0);
    _writeVarint(value);
  }

  void writeBytes(int field, Uint8List bytes) {
    _writeKey(field, 2);
    _writeVarint(bytes.length);
    _builder.add(bytes);
  }

  void writeLengthDelimited(int field, Uint8List bytes) {
    writeBytes(field, bytes);
  }

  Uint8List takeBytes() => _builder.takeBytes();

  void _writeKey(int field, int wireType) {
    _writeVarint((field << 3) | wireType);
  }

  void _writeVarint(int value) {
    var current = value;
    while ((current & ~0x7F) != 0) {
      _builder.addByte((current & 0x7F) | 0x80);
      current = current >> 7;
    }
    _builder.addByte(current);
  }
}
