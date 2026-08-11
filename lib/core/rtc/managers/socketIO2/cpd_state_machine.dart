import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'cpd_config.dart';
import 'cpd_enums.dart';
import 'cpd_models.dart';
import 'cpd_protocol.dart';

typedef SendPacketFn = Future<void> Function(Uint8List data);
typedef OnStateChangeFn = void Function(CpdActiveState state);
typedef OnEventFn = void Function(String eventType, Map<String, dynamic> data);

class CpdStateMachine {
  CpdStateMachine._internal();

  static final CpdStateMachine _instance = CpdStateMachine._internal();
  factory CpdStateMachine() => _instance;

  CpdSession? _session;
  CpdActiveState _state = CpdActiveState.idle;

  final List<DiscoverResult> _discoverResults = [];
  final Set<String> _seenDiscoverDedupKeys = {};
  final Set<String> _seenMessageKeys = {};
  final Map<String, List<MissingRange>> _pendingMissingRanges = {};

  Timer? _discoverTimer;
  Timer? _discoverWindowTimer;
  Timer? _authTimer;
  Timer? _authWindowTimer;
  Timer? _transferTimer;
  Timer? _silenceCheckTimer;
  Timer? _noProgressCheckTimer;
  Timer? _parseWaitTimer;

  int _discoverCount = 0;
  int _authRetryCount = 0;
  int _transferChunkIndex = 0;
  int _transferFirstSentCount = 0;
  // ignore: unused_field
  int _transferResendCount = 0;

  SendPacketFn? _sendPacket;
  OnStateChangeFn? _onStateChange;
  OnEventFn? _onEvent;

  CpdActiveState get state => _state;
  CpdSession? get session => _session;

  void configure({
    required SendPacketFn sendPacket,
    OnStateChangeFn? onStateChange,
    OnEventFn? onEvent,
  }) {
    _sendPacket = sendPacket;
    _onStateChange = onStateChange;
    _onEvent = onEvent;
  }

  void _setState(CpdActiveState newState) {
    _state = newState;
    _onStateChange?.call(newState);
  }

  void _emitEvent(String type, Map<String, dynamic> data) {
    _onEvent?.call(type, data);
  }

  bool get isActive =>
      _state != CpdActiveState.idle &&
      _state != CpdActiveState.completed &&
      _state != CpdActiveState.partialSuccess &&
      _state != CpdActiveState.failed;

  Future<void> startDistribution({
    required Uint8List fileData,
    required String fileName,
    required String nodeId,
    required List<DeviceType> expectedDevices,
  }) async {
    if (_sendPacket == null) return;
    if (isActive) return;

    _cleanupTimers();
    _session = CpdSession(
      sessionId: UuidV4.generate(),
      fileName: fileName,
      fileSize: fileData.length,
      fileSha256: _computeSha256(fileData),
      nodeId: nodeId,
      expandedSize: 0,
      requiredWorkspace: 0,
      chunkSize: CpdConfig.chunkPayloadSize,
      totalChunks: (fileData.length / CpdConfig.chunkPayloadSize).ceil(),
    );

    _discoverResults.clear();
    _seenDiscoverDedupKeys.clear();
    _seenMessageKeys.clear();
    _pendingMissingRanges.clear();
    _discoverCount = 0;
    _authRetryCount = 0;
    _transferChunkIndex = 0;
    _transferFirstSentCount = 0;
    _transferResendCount = 0;

    _setState(CpdActiveState.discovering);
    _emitEvent('discover_start', {});

    await _sendDiscoverNty();
    _discoverTimer = Timer.periodic(CpdConfig.discoverInterval, (_) async {
      _discoverCount++;
      if (_discoverCount < CpdConfig.discoverWindow.inSeconds) {
        await _sendDiscoverNty();
      }
    });

    _discoverWindowTimer = Timer(CpdConfig.discoverWindow, () {
      _discoverTimer?.cancel();
      _discoverTimer = null;
      _completeDiscovery();
    });
  }

  Future<void> _sendDiscoverNty() async {
    if (_sendPacket == null || _session == null) return;
    final msgId = UuidV4.generate();
    final packet = CpdPacket(
      sessionId: _session!.sessionId,
      messageId: msgId,
      body: const CpdMessage(CpdMessageType.discoverNty, {}),
    );
    await _sendPacket!(CpdProtocol.encodePacket(packet));
  }

  void _completeDiscovery() {
    if (_state != CpdActiveState.discovering) return;

    final esnMap = <String, List<DiscoverResult>>{};
    for (final r in _discoverResults) {
      esnMap.putIfAbsent(r.esn, () => []).add(r);
    }

    for (final entry in esnMap.entries) {
      if (entry.value.length > 1) {
        _emitEvent('esn_conflict', {
          'esn': entry.key.substring(entry.key.length - 6),
          'instances': entry.value.map((e) => e.currentIp).toList(),
        });
        _failDistribution(ErrorCode.esnConflict);
        return;
      }
    }

    _emitEvent('discover_complete', {
      'discovered': _discoverResults.length,
      'devices': _discoverResults
          .map(
            (d) => {
              'esnSuffix': d.esnSuffix,
              'deviceTypes': d.deviceTypes,
              'ip': d.currentIp,
            },
          )
          .toList(),
    });

    _startAuthentication();
  }

  Future<void> _startAuthentication() async {
    _setState(CpdActiveState.authenticating);
    _emitEvent('auth_start', {});

    final assignments = _buildAuthAssignments();
    if (assignments.isEmpty) {
      _failDistribution(ErrorCode.discoveryMismatch);
      return;
    }

    await _sendAuthNty(assignments);
    _authRetryCount = 0;

    _authTimer = Timer.periodic(CpdConfig.authRetryInterval, (_) async {
      _authRetryCount++;
      if (_authRetryCount < CpdConfig.authWindow.inSeconds) {
        await _sendAuthNty(assignments);
      }
    });

    _authWindowTimer = Timer(CpdConfig.authWindow, () {
      _authTimer?.cancel();
      _authTimer = null;
      _completeAuthentication();
    });
  }

  List<AuthAssignment> _buildAuthAssignments() {
    if (_session == null) return [];

    final assignments = <AuthAssignment>[];
    final usedEsns = <String>{};

    for (final result in _discoverResults) {
      if (usedEsns.contains(result.esn)) continue;

      for (final typeStr in result.deviceTypes) {
        final deviceType = _parseDeviceType(typeStr);
        if (deviceType == DeviceType.unknown) continue;

        assignments.add(
          AuthAssignment(
            deviceType: deviceType,
            esn: result.esn,
            nodeId: _session!.nodeId,
            deviceId: 'dc_${deviceType.name.toLowerCase()}_${result.esnSuffix}',
          ),
        );
      }
      usedEsns.add(result.esn);
    }

    return assignments;
  }

  DeviceType _parseDeviceType(String typeStr) {
    for (final dt in DeviceType.values) {
      if (dt.name.toLowerCase() == typeStr.toLowerCase()) return dt;
    }
    return DeviceType.unknown;
  }

  Future<void> _sendAuthNty(List<AuthAssignment> assignments) async {
    if (_sendPacket == null || _session == null) return;

    final chunks = _splitAssignments(assignments);
    for (final chunk in chunks) {
      final msgId = UuidV4.generate();
      final packet = CpdPacket(
        sessionId: _session!.sessionId,
        messageId: msgId,
        body: CpdMessage(CpdMessageType.authNty, {'assignments': chunk}),
      );
      final encoded = CpdProtocol.encodePacket(packet);
      if (encoded.length <= CpdConfig.maxUdpPayload) {
        await _sendPacket!(encoded);
      }
    }
  }

  List<List<AuthAssignment>> _splitAssignments(
    List<AuthAssignment> assignments,
  ) {
    final chunks = <List<AuthAssignment>>[];
    var currentChunk = <AuthAssignment>[];

    for (final a in assignments) {
      currentChunk.add(a);
      if (currentChunk.length >= 10) {
        chunks.add(currentChunk);
        currentChunk = <AuthAssignment>[];
      }
    }
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }
    return chunks;
  }

  void _completeAuthentication() {
    if (_discoverResults.isEmpty) {
      _failDistribution(ErrorCode.authTimeout);
      return;
    }
    _startTransfer();
  }

  Future<void> _startTransfer() async {
    if (_session == null) return;
    _setState(CpdActiveState.transferring);
    _emitEvent('transfer_start', {
      'fileName': _session!.fileName,
      'fileSize': _session!.fileSize,
      'totalChunks': _session!.totalChunks,
    });

    _transferChunkIndex = 0;
    _transferFirstSentCount = 0;
    _transferResendCount = 0;
    _pendingMissingRanges.clear();

    await _sendTransferStartNty();
    await _sendTransferStartNty();

    _sendChunksWithThrottle();
  }

  Future<void> _sendTransferStartNty() async {
    if (_sendPacket == null || _session == null) return;
    final msgId = UuidV4.generate();
    final packet = CpdPacket(
      sessionId: _session!.sessionId,
      messageId: msgId,
      body: CpdMessage(CpdMessageType.transferStartNty, {
        'fileName': _session!.fileName,
        'fileSize': _session!.fileSize,
        'fileSha256': _session!.fileSha256,
        'expandedSize': _session!.expandedSize,
        'requiredWorkspace': _session!.requiredWorkspace,
        'chunkSize': _session!.chunkSize,
        'totalChunks': _session!.totalChunks,
      }),
    );
    await _sendPacket!(CpdProtocol.encodePacket(packet));
  }

  void _sendChunksWithThrottle() {
    if (_session == null) return;

    final chunkCount = _session!.totalChunks;
    final chunkDurationMs =
        (CpdConfig.chunkPayloadSize * 8 * 1000) ~/
        CpdConfig.transferPayloadRateBps;

    void sendNextChunk() async {
      if (_transferChunkIndex >= chunkCount) {
        _onFirstRoundComplete();
        return;
      }

      await _sendSingleChunk(_transferChunkIndex);
      _transferChunkIndex++;
      _transferFirstSentCount++;

      _emitEvent('transfer_progress', {
        'sent': _transferFirstSentCount,
        'total': chunkCount,
        'percent': ((_transferFirstSentCount / chunkCount) * 100).round(),
      });

      _transferTimer = Timer(Duration(milliseconds: chunkDurationMs), () {
        sendNextChunk();
      });
    }

    sendNextChunk();
  }

  Future<void> _sendSingleChunk(int index) async {
    if (_sendPacket == null || _session == null) return;

    final payloadSize =
        index * CpdConfig.chunkPayloadSize + CpdConfig.chunkPayloadSize <=
            _session!.fileSize
        ? CpdConfig.chunkPayloadSize
        : _session!.fileSize - index * CpdConfig.chunkPayloadSize;

    final payload = Uint8List(payloadSize);
    final crc = Crc32.compute(payload);

    final msgId = UuidV4.generate();
    final packet = CpdPacket(
      sessionId: _session!.sessionId,
      messageId: msgId,
      body: CpdMessage(CpdMessageType.transferChunkNty, {
        'chunkIndex': index,
        'payload': payload,
        'payloadCrc32': crc,
      }),
    );
    await _sendPacket!(CpdProtocol.encodePacket(packet));
  }

  void _onFirstRoundComplete() {
    _sendTransferStartNty();
    _sendTransferStartNty();
    _sendTransferEndNty();

    _emitEvent('transfer_first_round_complete', {});
    _startSilenceCheck();
  }

  Future<void> _sendTransferEndNty() async {
    if (_sendPacket == null || _session == null) return;
    final msgId = UuidV4.generate();
    final packet = CpdPacket(
      sessionId: _session!.sessionId,
      messageId: msgId,
      body: const CpdMessage(CpdMessageType.transferEndNty, {}),
    );
    await _sendPacket!(CpdProtocol.encodePacket(packet));
  }

  void _startSilenceCheck() {
    _silenceCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkDeviceSilence();
    });

    _noProgressCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkDeviceNoProgress();
    });

    _transferTimer = Timer.periodic(CpdConfig.transferWaitRetryInterval, (_) {
      _resendStartAndEnd();
    });
  }

  void _checkDeviceSilence() {
    final now = DateTime.now();
    for (final device in _session?.devices ?? []) {
      if (device.isTerminal) continue;
      if (device.lastActivityTime != null) {
        final elapsed = now.difference(device.lastActivityTime!);
        if (elapsed >= CpdConfig.transferSilenceTimeout) {
          device.state = CpdActiveState.failed;
          device.errorCode = ErrorCode.transferSilenceTimeout;
          device.result = Result.failed;
          _emitEvent('device_failed', {
            'esnSuffix': device.esnSuffix,
            'reason': 'silence_timeout',
          });
        }
      }
    }
  }

  void _checkDeviceNoProgress() {
    // 简化实现：检测长时间无进展的设备
  }

  void _resendStartAndEnd() {
    _sendTransferStartNty();
    _sendTransferEndNty();
  }

  void handleIncomingPacket(CpdPacket packet) {
    if (_session == null) return;

    if (!_listEquals(packet.sessionId, _session!.sessionId)) return;

    final dedupKey = _computeMessageDedupKey(packet);
    if (_seenMessageKeys.contains(dedupKey)) return;
    _seenMessageKeys.add(dedupKey);

    final msg = packet.body;
    switch (msg.type) {
      case CpdMessageType.discoverRsp:
        _handleDiscoverRsp(msg);
        break;
      case CpdMessageType.authRsp:
        _handleAuthRsp(msg);
        break;
      case CpdMessageType.transferProgressRsp:
        _handleTransferProgressRsp(msg);
        break;
      case CpdMessageType.transferLosspackReq:
        _handleTransferLosspackReq(msg);
        break;
      case CpdMessageType.transferCompleteRsp:
        _handleTransferCompleteRsp(msg);
        break;
      case CpdMessageType.parseCompleteReq:
        _handleParseCompleteReq(packet);
        break;
      case CpdMessageType.parseCompleteAck:
        _handleParseCompleteAck(msg);
        break;
      default:
        break;
    }
  }

  String _computeMessageDedupKey(CpdPacket packet) {
    final sb = StringBuffer();
    for (final b in packet.sessionId) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    sb.write('_');
    for (final b in packet.messageId) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    sb.write('_');
    sb.write(packet.body.type.index);
    return sb.toString();
  }

  bool _listEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleDiscoverRsp(CpdMessage msg) {
    final result = DiscoverResult(
      esn: msg.esn,
      instanceNonce: msg.instanceNonce,
      deviceTypes: msg.deviceTypes,
      currentIp: msg.currentIp,
      subnetMask: msg.subnetMask,
    );

    if (_seenDiscoverDedupKeys.contains(result.dedupKey)) return;
    _seenDiscoverDedupKeys.add(result.dedupKey);

    _discoverResults.add(result);
    _emitEvent('discover_device', {
      'esnSuffix': result.esnSuffix,
      'deviceTypes': result.deviceTypes,
      'ip': result.currentIp,
    });
  }

  void _handleAuthRsp(CpdMessage msg) {
    if (msg.result == Result.failed) {
      _emitEvent('auth_failed', {'errorCode': msg.errorCode.name});
      _failDistribution(msg.errorCode);
      return;
    }

    final client = msg.client;
    final status = DeviceStatus(
      esn: client.esn,
      esnSuffix: client.esn.length >= 6
          ? client.esn.substring(client.esn.length - 6)
          : client.esn,
      deviceType: client.deviceTypes.isNotEmpty
          ? _parseDeviceType(client.deviceTypes.first)
          : DeviceType.unknown,
      deviceId: msg.bindings.isNotEmpty ? msg.bindings.first.deviceId : '',
      currentIp: '',
    );
    status.state = CpdActiveState.authenticating;
    status.lastActivityTime = DateTime.now();
    _session?.devices.add(status);

    _emitEvent('auth_success', {
      'esnSuffix': status.esnSuffix,
      'deviceTypes': client.deviceTypes,
    });
  }

  void _handleTransferProgressRsp(CpdMessage msg) {
    final client = msg.client;
    for (final device in _session?.devices ?? []) {
      if (device.esn == client.esn) {
        device.receivedChunks = msg.receivedChunks;
        device.totalChunks = msg.totalChunks;
        device.progressPercent = msg.percent;
        device.lastActivityTime = DateTime.now();

        if (msg.receivedChunks > device.receivedHighWatermark) {
          device.receivedHighWatermark = msg.receivedChunks;
        }

        _emitEvent('device_progress', {
          'esnSuffix': device.esnSuffix,
          'percent': msg.percent,
          'receivedChunks': msg.receivedChunks,
          'totalChunks': msg.totalChunks,
        });
        break;
      }
    }
  }

  void _handleTransferLosspackReq(CpdMessage msg) {
    final client = msg.client;
    final esnKey = client.esn;

    if (!_pendingMissingRanges.containsKey(esnKey)) {
      _pendingMissingRanges[esnKey] = [];
    }
    _pendingMissingRanges[esnKey]!.addAll(msg.missingRanges);
    _pendingMissingRanges[esnKey] = MissingRange.merge(
      _pendingMissingRanges[esnKey]!,
    );

    _resendMissingChunks(esnKey);
  }

  Future<void> _resendMissingChunks(String esnKey) async {
    final ranges = _pendingMissingRanges[esnKey];
    if (ranges == null || ranges.isEmpty) return;

    _transferResendCount++;

    _emitEvent('resuming', {
      'esn': esnKey.substring(esnKey.length - 6),
      'ranges': ranges.map((r) => {'start': r.start, 'end': r.end}).toList(),
    });

    for (final range in ranges) {
      for (int i = range.start; i <= range.end; i++) {
        await _sendSingleChunk(i);
      }
    }

    _sendTransferStartNty();
    _sendTransferEndNty();
  }

  void _handleTransferCompleteRsp(CpdMessage msg) {
    final client = msg.client;
    for (final device in _session?.devices ?? []) {
      if (device.esn == client.esn) {
        if (msg.result == Result.failed) {
          device.state = CpdActiveState.failed;
          device.result = Result.failed;
          device.errorCode = msg.errorCode;
          device.transferStage = msg.transferStage;
          _emitEvent('device_failed', {
            'esnSuffix': device.esnSuffix,
            'stage': msg.transferStage.name,
            'errorCode': msg.errorCode.name,
          });
        } else {
          device.state = CpdActiveState.waitingParse;
          device.result = Result.success;
          device.transferStage = msg.transferStage;
          device.lastActivityTime = DateTime.now();
          _emitEvent('device_transfer_complete', {
            'esnSuffix': device.esnSuffix,
            'stage': msg.transferStage.name,
          });

          _startParseWaitTimer(device);
        }
        break;
      }
    }
  }

  void _startParseWaitTimer(DeviceStatus device) {
    Future.delayed(CpdConfig.parseResultWaitTimeout, () {
      if (device.state == CpdActiveState.waitingParse) {
        device.state = CpdActiveState.failed;
        device.result = Result.failed;
        device.errorCode = ErrorCode.parseTimeout;
        _emitEvent('device_parse_timeout', {'esnSuffix': device.esnSuffix});
        _checkAllTerminal();
      }
    });
  }

  void _handleParseCompleteReq(CpdPacket packet) {
    final msg = packet.body;
    final client = msg.client;

    for (final device in _session?.devices ?? []) {
      if (device.esn == client.esn) {
        device.lastActivityTime = DateTime.now();
        if (msg.result == Result.success) {
          device.state = CpdActiveState.completed;
          device.result = Result.success;
        } else {
          device.state = CpdActiveState.failed;
          device.result = Result.failed;
          device.errorCode = msg.errorCode;
        }

        _emitEvent('device_parse_complete', {
          'esnSuffix': device.esnSuffix,
          'result': msg.result.name,
          'errorCode': msg.errorCode.name,
        });

        _sendParseCompleteAck(client.esn, client.deviceTypes, msg.result);
        break;
      }
    }

    _checkAllTerminal();
  }

  Future<void> _sendParseCompleteAck(
    String esn,
    List<String> deviceTypes,
    Result result,
  ) async {
    if (_sendPacket == null || _session == null) return;
    final msgId = UuidV4.generate();
    final packet = CpdPacket(
      sessionId: _session!.sessionId,
      messageId: msgId,
      body: CpdMessage(CpdMessageType.parseCompleteAck, {
        'esn': esn,
        'deviceTypes': deviceTypes,
        'result': result.index,
      }),
    );
    await _sendPacket!(CpdProtocol.encodePacket(packet));
  }

  void _handleParseCompleteAck(CpdMessage msg) {
    // CPDS 端通常不需要处理 ACK
  }

  void _checkAllTerminal() {
    final devices = _session?.devices ?? [];
    if (devices.isEmpty) return;

    final allTerminal = devices.every((d) => d.isTerminal);
    if (allTerminal) {
      _completeDistribution();
    }
  }

  void _completeDistribution() {
    final devices = _session?.devices ?? [];
    final totalCount = devices.length;
    final successCount = devices
        .where((d) => d.result == Result.success)
        .length;
    final failedCount = devices.where((d) => d.result == Result.failed).length;

    if (successCount == totalCount) {
      _setState(CpdActiveState.completed);
      _emitEvent('distribution_complete', {
        'status': 'completed',
        'successCount': successCount,
        'totalCount': totalCount,
      });
    } else if (successCount > 0) {
      _setState(CpdActiveState.partialSuccess);
      _emitEvent('distribution_complete', {
        'status': 'partial_success',
        'successCount': successCount,
        'failedCount': failedCount,
        'totalCount': totalCount,
      });
    } else {
      _setState(CpdActiveState.failed);
      _emitEvent('distribution_complete', {
        'status': 'failed',
        'successCount': 0,
        'failedCount': failedCount,
        'totalCount': totalCount,
      });
    }

    _cleanupTimers();
  }

  void _failDistribution(ErrorCode errorCode) {
    _setState(CpdActiveState.failed);
    _emitEvent('distribution_failed', {'errorCode': errorCode.name});
    _cleanupTimers();
  }

  void stopDistribution() {
    _cleanupTimers();
    _setState(CpdActiveState.idle);
    _session = null;
  }

  void _cleanupTimers() {
    _discoverTimer?.cancel();
    _discoverTimer = null;
    _discoverWindowTimer?.cancel();
    _discoverWindowTimer = null;
    _authTimer?.cancel();
    _authTimer = null;
    _authWindowTimer?.cancel();
    _authWindowTimer = null;
    _transferTimer?.cancel();
    _transferTimer = null;
    _silenceCheckTimer?.cancel();
    _silenceCheckTimer = null;
    _noProgressCheckTimer?.cancel();
    _noProgressCheckTimer = null;
    _parseWaitTimer?.cancel();
    _parseWaitTimer = null;
  }

  Uint8List _computeSha256(Uint8List data) {
    // 使用简单的哈希实现，实际应使用标准 SHA-256
    return _simpleHash256(data);
  }

  Uint8List _simpleHash256(Uint8List data) {
    // 简化的 32 字节哈希 (实际部署请使用标准 SHA-256)
    final result = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      result[i] = (data.isEmpty ? 0 : data[i % data.length] + i) & 0xFF;
    }
    return result;
  }
}

/// UUID v4 生成工具
class UuidV4 {
  static final _random = Random.secure();

  /// 生成随机 UUID v4 (16字节)
  static Uint8List generate() {
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      bytes[i] = _random.nextInt(256);
    }
    // 设置版本 4 (0100)
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    // 设置变体位
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    return bytes;
  }
}

/// CRC32 计算工具
class Crc32 {
  static const List<int> _table = [
    0x00000000,
    0x77073096,
    0xEE0E612C,
    0x990951BA,
    0x076DC419,
    0x706AF48F,
    0xE963A535,
    0x9E6495A3,
    0x0EDB8832,
    0x79DCB8A4,
    0xE0D5E91E,
    0x97D2D988,
    0x09B64C2B,
    0x7EB17CBD,
    0xE7B82D09,
    0x90BF1D9F,
    0x1DB71064,
    0x6AB020F2,
    0xF3B97148,
    0x84BE41DE,
    0x1ADAD47D,
    0x6DDDE4EB,
    0xF4D4B551,
    0x83D385C7,
    0x136C9856,
    0x646BA8C0,
    0xFD62F97A,
    0x8A65C9EC,
    0x14015C4F,
    0x63066CD9,
    0xFA0F3D63,
    0x8D080DF5,
    0x3B6E20C8,
    0x4C69105E,
    0xD56041E4,
    0xA2677172,
    0x3C03E4D1,
    0x4B04D447,
    0xD20D85FD,
    0xA50AB56B,
    0x35B5A8FA,
    0x42B2986C,
    0xDBBBB9D6,
    0xACBCB447,
    0x32D86CE3,
    0x45DF5D75,
    0xDCB69A81,
    0xABD44811,
    0x25D9F34,
    0x5291E3D2,
    0xC5D07268,
    0xB2D742FE,
    0x22D9F34,
    0x55DEF3D,
    0xCCDE927,
    0xBB89451E,
    0x2C4DFB4,
    0x5B4AEBD,
    0xC24D2ED8,
    0xB54A1E4D,
    0x2B0038D7,
    0x5C070841,
    0xC500585C,
    0xB20738CA,
  ];

  static int compute(Uint8List data) {
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      final index = (crc ^ byte) & 0xFF;
      crc = (crc >> 8) ^ _table[index];
    }
    return crc ^ 0xFFFFFFFF;
  }
}
