import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';

/// 自更新的真实 UDP 广播传输。
///
/// - 发送：向 255.255.255.255 与回环地址广播到 CPDC 的 39003 端口；
/// - 接收：绑定 CPDS 的 39004 端口，收集 CPDC 的上行回复。
class UdpUpdateTransport implements UpdateTransport {
  UdpUpdateTransport();

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _loopbackSocket;
  RawDatagramSocket? _receiveSocket;
  final StreamController<Uint8List> _replyController =
      StreamController<Uint8List>.broadcast();

  bool _initialized = false;
  bool _closed = false;

  @override
  Stream<Uint8List> get replies => _replyController.stream;

  /// 绑定发送/接收 socket。重复调用会先关闭旧 socket。
  Future<void> init() async {
    await close();
    _broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _broadcastSocket!.broadcastEnabled = true;

    _loopbackSocket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    _loopbackSocket!.broadcastEnabled = true;

    _receiveSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      UpdateProtocol.cpdsReceivePort,
    );
    _receiveSocket!.listen(_onReceive);
    _initialized = true;
    _closed = false;
  }

  @override
  Future<void> send(Uint8List data) async {
    if (!_initialized || _closed) {
      return;
    }
    _sendTo(
      _broadcastSocket,
      data,
      InternetAddress('255.255.255.255'),
      UpdateProtocol.cpdcReceivePort,
    );
    _sendTo(
      _loopbackSocket,
      data,
      InternetAddress.loopbackIPv4,
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
      return;
    }
    try {
      socket.send(data, address, port);
    } catch (_) {
      // 发送失败不影响整体流程。
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
    Datagram? datagram;
    while ((datagram = socket.receive()) != null) {
      if (!_replyController.isClosed) {
        _replyController.add(Uint8List.fromList(datagram!.data));
      }
    }
  }

  @override
  Future<void> close() async {
    if (_closed && !_initialized) {
      return;
    }
    _closed = true;
    _initialized = false;
    _broadcastSocket?.close();
    _loopbackSocket?.close();
    _receiveSocket?.close();
    _broadcastSocket = null;
    _loopbackSocket = null;
    _receiveSocket = null;
  }
}
