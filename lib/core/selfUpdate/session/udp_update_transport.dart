import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol_logger.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';

/// 自更新的真实 UDP 广播传输。
///
/// - 发送：向 255.255.255.255 广播到 CPDC 的 39003 端口；
/// - 接收：绑定 CPDS 的 39004 端口，收集 CPDC 的上行回复。
class UdpUpdateTransport implements UpdateTransport {
  UdpUpdateTransport();

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _receiveSocket;
  StreamSubscription<RawSocketEvent>? _receiveSubscription;
  final StreamController<UpdateDatagram> _replyController =
      StreamController<UpdateDatagram>.broadcast();

  bool _initialized = false;
  bool _closed = false;

  @override
  Stream<UpdateDatagram> get replies => _replyController.stream;

  /// 绑定发送/接收 socket。重复调用会先关闭旧 socket。
  ///
  /// [interfaceIp] 指定广播 socket 绑定的网卡 IPv4；为空时绑定 anyIPv4（走默认网卡）。
  Future<void> init({String? interfaceIp}) async {
    await close();
    final bindAddress = interfaceIp == null || interfaceIp.isEmpty
        ? InternetAddress.anyIPv4
        : InternetAddress(interfaceIp);
    _broadcastSocket = await RawDatagramSocket.bind(bindAddress, 0);
    _broadcastSocket!.broadcastEnabled = true;

    _receiveSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      UpdateProtocol.cpdsReceivePort,
    );
    _receiveSubscription = _receiveSocket!.listen(_onReceive);
    _initialized = true;
    _closed = false;
    UpdateProtocolLogger.logOpen();
  }

  @override
  Future<void> send(Uint8List data) async {
    if (!_initialized || _closed) {
      return;
    }
    UpdateProtocolLogger.logSend(data);
    _sendTo(
      _broadcastSocket,
      data,
      InternetAddress('255.255.255.255'),
      UpdateProtocol.cpdcReceivePort,
    );
  }

  void _sendTo(
    RawDatagramSocket? socket,
    Uint8List data,
    InternetAddress address,
    int port,
  ) {
    if (socket == null) {
      debugPrint('[自更新][UDP][发送失败] $address:$port - socket 未就绪');
      return;
    }
    try {
      final sent = socket.send(data, address, port);
      final isPacket = String.fromCharCodes(
        data,
      ).startsWith(UpdateProtocol.packetPrefix);
      final logTransportLine =
          !isPacket || UpdateProtocolLogger.packetLogLevel == PacketLogLevel.full;
      if (logTransportLine) {
        debugPrint('[自更新][UDP][发送] $address:$port - $sent 字节');
      }
    } catch (e) {
      debugPrint('[自更新][UDP][发送失败] $address:$port - $e');
    }
  }

  void _onReceive(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final socket = _receiveSocket;
    if (socket == null) {
      return;
    }
    while (true) {
      final datagram = socket.receive();
      if (datagram == null) {
        break;
      }
      final payload = Uint8List.fromList(datagram.data);
      final text = String.fromCharCodes(payload);
      final isPacketAck = text.startsWith(UpdateProtocol.packetOkPrefix) ||
          text.startsWith(UpdateProtocol.packetFailPrefix);
      final logTransportLine =
          !isPacketAck ||
          UpdateProtocolLogger.packetLogLevel == PacketLogLevel.full;
      if (logTransportLine) {
        debugPrint(
          '[自更新][UDP][接收] ${datagram.address.address}:${datagram.port} - '
          '${payload.length} 字节',
        );
      }
      UpdateProtocolLogger.logReceive(
        payload,
        sourceIp: datagram.address.address,
      );
      if (!_replyController.isClosed) {
        _replyController.add(
          UpdateDatagram(data: payload, sourceIp: datagram.address.address),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    if (_closed && !_initialized) {
      return;
    }
    final wasOpen = _receiveSocket != null;
    _closed = true;
    _initialized = false;
    await _receiveSubscription?.cancel();
    _receiveSubscription = null;
    _broadcastSocket?.close();
    _receiveSocket?.close();
    _broadcastSocket = null;
    _receiveSocket = null;
    if (wasOpen) {
      UpdateProtocolLogger.logClose();
    }
  }
}
