import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_config.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_enums.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_models.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_protocol.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_state_machine.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.type.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';
import 'package:flutter_kts_template/logger/logger.dart';

/// CPDS (Communication Plan Distribution Server) 管理器
///
/// 实现 CPDS 端在 Flutter Android 上的通信保障配置包下发功能。
/// 使用原生 UDP + Proto3 二进制协议与 CPDC 设备通信。
class SocketIO2Manager implements RtcAbstract {
  SocketIO2Manager._internal();

  static final SocketIO2Manager _instance = SocketIO2Manager._internal();
  factory SocketIO2Manager() => _instance;

  RawDatagramSocket? _socket;
  bool _initialized = false;
  bool _connected = false;

  final CpdStateMachine _stateMachine = CpdStateMachine();

  final StreamController<RtcReceive> _onDataStreamController =
      StreamController<RtcReceive>.broadcast();
  final StreamController<RtcEvent> _onEventController =
      StreamController<RtcEvent>.broadcast();

  final StreamController<CpdActiveState> _onStateController =
      StreamController<CpdActiveState>.broadcast();
  final StreamController<Map<String, dynamic>> _onCpdEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _connected;
  CpdActiveState get cpdState => _stateMachine.state;
  CpdSession? get cpdSession => _stateMachine.session;

  Stream<CpdActiveState> get stateStream => _onStateController.stream;
  Stream<Map<String, dynamic>> get cpdEventStream =>
      _onCpdEventController.stream;

  @override
  Future<void> init(String localPeerAddress) async {
    if (_initialized) {
      await disconnect();
    }

    try {
      // 绑定 CPDS 接收端口 39002，启用广播 + 地址重用
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        CpdConfig.cpdsPort,
        reuseAddress: true,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handleIncomingData(
              datagram.data,
              datagram.address.address,
              datagram.port,
            );
          }
        }
      });

      _stateMachine.configure(
        sendPacket: _sendPacket,
        onStateChange: (state) {
          _onStateController.sink.add(state);
          GlobalLogger.logInfo('CPDS State: ${state.name}');
        },
        onEvent: (type, data) {
          _onCpdEventController.sink.add({'type': type, ...data});
          GlobalLogger.logInfo('CPDS Event: $type - $data');
        },
      );

      _initialized = true;
      _connected = true;
      _onEventController.sink.add(RtcEvent(type: RtcEventType.created));
      GlobalLogger.logInfo('CPDS SocketIO2 初始化成功 (端口: ${CpdConfig.cpdsPort})');
    } catch (e) {
      GlobalLogger.logError('CPDS 初始化失败: $e');
      _onEventController.sink.add(
        RtcEvent(type: RtcEventType.error, msg: e.toString()),
      );
    }
  }

  void _handleIncomingData(Uint8List data, String address, int port) {
    final packet = CpdProtocol.decodePacket(data);
    if (packet == null) {
      GlobalLogger.logDebug(
        'CPDS 收到无效报文: ${data.length} bytes from $address:$port',
      );
      return;
    }

    GlobalLogger.logDebug(
      'CPDS 收到报文: ${packet.body.type.name} from $address:$port',
    );

    _onDataStreamController.sink.add(
      RtcReceive(address: address, data: data, port: port),
    );

    _stateMachine.handleIncomingPacket(packet);
  }

  Future<void> _sendPacket(Uint8List data) async {
    if (!_connected || _socket == null) return;

    try {
      // 广播地址 + 环回地址双发，确保同机通信可靠
      _socket!.send(
        data,
        InternetAddress('255.255.255.255'),
        CpdConfig.cpdcPort,
      );
      _socket!.send(data, InternetAddress('127.0.0.1'), CpdConfig.cpdcPort);

      GlobalLogger.logDebug('CPDS 发送 ${data.length} 字节 (广播+环回)');
    } catch (e) {
      GlobalLogger.logError('CPDS 发送失败: $e');
    }
  }

  @override
  Future<void> connect(String remotePeerAddress) async {}

  @override
  Future<void> disconnect() async {
    try {
      _stateMachine.stopDistribution();
      if (_connected) {
        _socket?.close();
        _socket = null;
        _connected = false;
        _onEventController.sink.add(RtcEvent(type: RtcEventType.disConnect));
      }
      _initialized = false;
      GlobalLogger.logInfo('CPDS 已断开');
    } catch (e) {
      GlobalLogger.logError('CPDS 断开异常: $e');
    }
  }

  @override
  Future<void> write(Uint8List data, String remotePeerAddress) async {
    await _sendPacket(data);
  }

  @override
  Stream<RtcEvent> get eventStream => _onEventController.stream;

  @override
  Stream<RtcReceive> get receiveStream => _onDataStreamController.stream;

  @override
  Future<List<String>> getRemotePeers() async {
    return [];
  }

  // ============ CPDS 业务 API ============

  /// 开始下发流程
  Future<void> startDistribution({
    required Uint8List fileData,
    required String fileName,
    required String nodeId,
    List<DeviceType> expectedDevices = const [],
  }) async {
    if (!_connected) {
      GlobalLogger.logError('CPDS 未初始化，无法开始下发');
      return;
    }

    if (fileData.length > CpdConfig.maxFileSize) {
      GlobalLogger.logError('文件超过最大限制 (${CpdConfig.maxFileSize} bytes)');
      return;
    }

    await _stateMachine.startDistribution(
      fileData: fileData,
      fileName: fileName,
      nodeId: nodeId,
      expectedDevices: expectedDevices,
    );
  }

  /// 停止下发流程
  void stopDistribution() {
    _stateMachine.stopDistribution();
  }

  /// 获取当前会话状态
  CpdSession? getCurrentSession() => _stateMachine.session;

  /// 获取当前活动状态
  CpdActiveState getActiveState() => _stateMachine.state;
}
