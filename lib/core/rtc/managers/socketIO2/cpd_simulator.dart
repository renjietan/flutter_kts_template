import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'cpd_config.dart';
import 'cpd_enums.dart';
import 'cpd_models.dart';
import 'cpd_protocol.dart';

/// CPDC 模拟器 - 用于本地测试 CPDS 下发流程
///
/// 监听 CPDS 发送的消息并模拟多个 CPDC 设备的响应。
class CpdSimulator {
  CpdSimulator._internal();
  static final CpdSimulator instance = CpdSimulator._internal();

  RawDatagramSocket? _socket;
  bool _running = false;

  // 模拟的设备列表
  final List<_SimDevice> _devices = [];

  // 会话状态
  int _totalChunks = 0;

  // 定时器
  Timer? _parseTimer;

  // 消息日志回调
  final List<String> _logs = [];
  void Function(String msg)? _onLog;

  bool get isRunning => _running;
  List<_SimDevice> get devices => List.unmodifiable(_devices);
  List<String> get logs => List.unmodifiable(_logs);

  /// 启动模拟器
  Future<void> start({
    int deviceCount = 2,
    List<DeviceType> deviceTypes = const [DeviceType.server, DeviceType.iec],
    Function(String msg)? onLog,
  }) async {
    if (_running) return;

    _onLog = onLog;
    _log('正在启动 CPDC 模拟器...');

    // 绑定到 CPDC 端口 39001，启用地址重用
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      CpdConfig.cpdcPort,
      reuseAddress: true,
    );

    _running = true;
    _log('✅ CPDC 模拟器已启动 (端口: ${CpdConfig.cpdcPort})');

    // 初始化模拟设备
    _devices.clear();
    for (int i = 0; i < deviceCount; i++) {
      final type = deviceTypes[i % deviceTypes.length];
      _devices.add(
        _SimDevice(
          esn:
              'ESN${type.value.toString().padLeft(3, '0')}${(100000 + i * 12345).toString()}',
          deviceType: type,
          ip: '127.0.0.1',
        ),
      );
    }
    _log(
      '📱 已模拟 ${_devices.length} 台设备: ${_devices.map((d) => '${d.deviceType.displayName}(${d.esnSuffix})').join(', ')}',
    );

    // 监听数据包
    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          _handleIncoming(datagram.data);
        }
      }
    });
  }

  /// 停止模拟器
  Future<void> stop() async {
    _parseTimer?.cancel();
    _parseTimer = null;

    _socket?.close();
    _socket = null;

    _running = false;
    _devices.clear();
    _totalChunks = 0;
    _log('⏹️ CPDC 模拟器已停止');
  }

  void _handleIncoming(Uint8List data) {
    final packet = CpdProtocol.decodePacket(data);
    if (packet == null) return;

    final msg = packet.body;
    _log('📥 收到: ${msg.type.name}');

    switch (msg.type) {
      case CpdMessageType.discoverNty:
        _onDiscoverNty(packet);
        break;
      case CpdMessageType.authNty:
        _onAuthNty(packet, msg);
        break;
      case CpdMessageType.transferStartNty:
        _onTransferStartNty(packet, msg);
        break;
      case CpdMessageType.transferChunkNty:
        _onTransferChunkNty(packet, msg);
        break;
      case CpdMessageType.transferEndNty:
        _onTransferEndNty(packet);
        break;
      case CpdMessageType.parseCompleteAck:
        _onParseCompleteAck(msg);
        break;
      default:
        break;
    }
  }

  /// 处理 DISCOVER_NTY → 回复 DISCOVER_RSP
  void _onDiscoverNty(CpdPacket packet) {
    _log('🔍 发现请求，回复 ${_devices.length} 台设备...');
    for (final device in _devices) {
      final rsp = _buildDiscoverRsp(packet.sessionId, device);
      _sendPacket(rsp);
    }
  }

  CpdPacket _buildDiscoverRsp(Uint8List sessionId, _SimDevice device) {
    final nonce = Uint8List(8);
    final rand = Random.secure();
    for (int i = 0; i < 8; i++) {
      nonce[i] = rand.nextInt(256);
    }

    return CpdPacket(
      sessionId: sessionId,
      messageId: _genMsgId(),
      body: CpdMessage(CpdMessageType.discoverRsp, {
        'esn': device.esn,
        'instanceNonce': nonce,
        'deviceTypes': [device.deviceType.name],
        'currentIp': device.ip,
        'subnetMask': '255.255.255.0',
      }),
    );
  }

  /// 处理 AUTH_NTY → 回复 AUTH_RSP
  void _onAuthNty(CpdPacket packet, CpdMessage msg) {
    _log('🔐 认证请求，回复认证结果...');

    final assignments = msg.assignments;
    for (final assignment in assignments) {
      final device = _devices.where((d) => d.esn == assignment.esn).firstOrNull;
      if (device == null) continue;

      final rsp = _buildAuthRsp(packet.sessionId, device, assignment);
      _sendPacket(rsp);
      device.deviceId = assignment.deviceId;
      device.authenticated = true;
    }
  }

  CpdPacket _buildAuthRsp(
    Uint8List sessionId,
    _SimDevice device,
    AuthAssignment assignment,
  ) {
    return CpdPacket(
      sessionId: sessionId,
      messageId: _genMsgId(),
      body: CpdMessage(CpdMessageType.authRsp, {
        'client': ClientIdentity(
          esn: device.esn,
          deviceTypes: [device.deviceType.name],
        ),
        'result': Result.success.index,
        'nodeId': assignment.nodeId,
        'bindings': [
          AuthBinding(
            deviceType: device.deviceType,
            nodeId: assignment.nodeId,
            deviceId: assignment.deviceId,
          ),
        ],
        'errorCode': ErrorCode.unspecified.value,
      }),
    );
  }

  /// 处理 TRANSFER_START_NTY → 开始接收数据
  void _onTransferStartNty(CpdPacket packet, CpdMessage msg) {
    _totalChunks = msg.totalChunks;

    _log(
      '📦 传输开始: ${msg.fileName} (${msg.fileSize} bytes, ${msg.totalChunks} 分片)',
    );

    // 重置设备接收状态
    for (final device in _devices) {
      device.receivedChunks.clear();
      device.transferStage = TransferStage.precheck;
      device.lastProgressTime = DateTime.now();
    }

    // 回复 TransferProgressRsp
    _sendProgressUpdates(packet.sessionId);
  }

  /// 处理 TRANSFER_CHUNK_NTY → 记录分片
  void _onTransferChunkNty(CpdPacket packet, CpdMessage msg) {
    final chunkIndex = msg.chunkIndex;

    for (final device in _devices) {
      if (device.transferStage == TransferStage.receive ||
          device.transferStage == TransferStage.precheck) {
        device.receivedChunks[chunkIndex] = msg.payload;
        device.transferStage = TransferStage.receive;

        // 每 10 个分片发送一次进度
        if (device.receivedChunks.length % 10 == 0 ||
            chunkIndex == _totalChunks - 1) {
          _sendProgressUpdates(packet.sessionId);
        }
      }
    }
  }

  /// 处理 TRANSFER_END_NTY → 发送完成响应
  void _onTransferEndNty(CpdPacket packet) {
    _log('✅ 传输结束，发送完成响应...');

    for (final device in _devices) {
      device.transferStage = TransferStage.verify;

      final receivedCount = device.receivedChunks.length;
      final percent = _totalChunks > 0
          ? ((receivedCount / _totalChunks) * 100).round()
          : 100;

      // 发送完成响应
      final completeRsp = CpdPacket(
        sessionId: packet.sessionId,
        messageId: _genMsgId(),
        body: CpdMessage(CpdMessageType.transferCompleteRsp, {
          'client': ClientIdentity(
            esn: device.esn,
            deviceTypes: [device.deviceType.name],
          ),
          'result': Result.success.index,
          'stage': TransferStage.receive.value,
          'receivedChunks': receivedCount,
          'totalChunks': _totalChunks,
          'errorCode': ErrorCode.unspecified.value,
        }),
      );
      _sendPacket(completeRsp);

      _log(
        '  📱 ${device.esnSuffix}: 收到 $receivedCount/$_totalChunks 分片 ($percent%)',
      );

      // 模拟解析完成（延迟 2 秒）
      _sendParseCompleteReq(packet.sessionId, device);
    }
  }

  /// 发送进度更新
  void _sendProgressUpdates(Uint8List sessionId) {
    for (final device in _devices) {
      if (device.transferStage != TransferStage.receive &&
          device.transferStage != TransferStage.precheck) {
        continue;
      }

      final receivedCount = device.receivedChunks.length;
      final percent = _totalChunks > 0
          ? ((receivedCount / _totalChunks) * 100).round()
          : 0;

      final progressRsp = CpdPacket(
        sessionId: sessionId,
        messageId: _genMsgId(),
        body: CpdMessage(CpdMessageType.transferProgressRsp, {
          'client': ClientIdentity(
            esn: device.esn,
            deviceTypes: [device.deviceType.name],
          ),
          'receivedChunks': receivedCount,
          'totalChunks': _totalChunks,
          'percent': percent,
        }),
      );
      _sendPacket(progressRsp);
    }
  }

  /// 发送解析完成请求（模拟设备解析完成）
  void _sendParseCompleteReq(Uint8List sessionId, _SimDevice device) {
    _parseTimer?.cancel();
    _parseTimer = Timer(const Duration(seconds: 2), () {
      _log('🔧 ${device.esnSuffix} 解析完成，发送 PARSE_COMPLETE_REQ...');

      final req = CpdPacket(
        sessionId: sessionId,
        messageId: _genMsgId(),
        body: CpdMessage(CpdMessageType.parseCompleteReq, {
          'client': ClientIdentity(
            esn: device.esn,
            deviceTypes: [device.deviceType.name],
          ),
          'result': Result.success.index,
          'nodeId': 'node_001',
          'bindings': [
            AuthBinding(
              deviceType: device.deviceType,
              nodeId: 'node_001',
              deviceId: device.deviceId,
            ),
          ],
          'typeResults': [
            ParseTypeResult(
              deviceType: device.deviceType,
              deviceId: device.deviceId,
              stage: ParseStage.receive,
              errorCode: ErrorCode.unspecified,
            ),
          ],
          'errorCode': ErrorCode.unspecified.value,
        }),
      );
      _sendPacket(req);
      device.parseCompleted = true;
    });
  }

  /// 处理 PARSE_COMPLETE_ACK
  void _onParseCompleteAck(CpdMessage msg) {
    _log('📨 收到解析确认: ${msg.ackEsn} → ${msg.result.name}');
  }

  /// 发送数据包到 CPDS
  void _sendPacket(CpdPacket packet) {
    if (_socket == null) return;

    final data = CpdProtocol.encodePacket(packet);

    try {
      // 发送到 CPDS 端口 39002 (环回地址)
      _socket!.send(data, InternetAddress('127.0.0.1'), CpdConfig.cpdsPort);

      _log('📤 发送 ${packet.body.type.name} (${data.length} bytes)');
    } catch (e) {
      _log('❌ 发送失败: $e');
    }
  }

  /// 生成消息 ID
  Uint8List _genMsgId() {
    final bytes = Uint8List(16);
    final rand = Random.secure();
    for (int i = 0; i < 16; i++) {
      bytes[i] = rand.nextInt(256);
    }
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    return bytes;
  }

  /// 字节数组转十六进制字符串 (保留供将来使用)
  // ignore: unused_element
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _log(String msg) {
    final line = '[SIM] $msg';
    _logs.insert(0, line);
    if (_logs.length > 500) {
      _logs.removeLast();
    }
    _onLog?.call(line);
  }
}

/// 模拟设备
class _SimDevice {
  final String esn;
  final DeviceType deviceType;
  final String ip;

  String deviceId = '';
  bool authenticated = false;
  bool parseCompleted = false;
  TransferStage transferStage = TransferStage.unspecified;
  final Map<int, Uint8List> receivedChunks = {};
  DateTime? lastProgressTime;

  _SimDevice({required this.esn, required this.deviceType, required this.ip});

  String get esnSuffix => esn.length >= 6 ? esn.substring(esn.length - 6) : esn;
}
