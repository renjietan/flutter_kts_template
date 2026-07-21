import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.dart';
import 'package:flutter_kts_template/logger/logger.dart';

class SocketIOManager implements RtcAbstract {
  SocketIOManager._internal();

  static final SocketIOManager _instance = SocketIOManager._internal();

  RawDatagramSocket? _socket;

  final StreamController<Uint8List> _onDataStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<RtcEvent> _onEventStreamController =
      StreamController<RtcEvent>.broadcast();

  factory SocketIOManager() {
    return _instance;
  }

  bool get isConnected => _socket != null;

  // 参数 peerAddress 无需传, socket 地址采用 InternetAddress.anyIPv4 端口为0(随机分配端口)
  @override
  Future<void> init(String localPeerAddress) async {
    await disconnect();
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    // 启用广播权限
    _socket!.broadcastEnabled = true;
    _socket!.listen((RawSocketEvent event) {});
  }

  Future<void> connect(String remotePeerAddress) async {}

  @override
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }
  }

  // 【remotePeerAddress】 无需传, 广播默认只向地址 255.255.255.255 发送消息，端口号也可以写死
  @override
  Future<void> write(Uint8List data, String remotePeerAddress) async {
    if (!isConnected) {
      await connect("不用传");
    }
    try {
      final broadcastAddress = InternetAddress('255.255.255.255');
      // 为了获取发送字节数，使用 send 方法
      int? bytesSent = _socket?.send(data, broadcastAddress, 3333);

      SimplePopup.toast('已成功向 $broadcastAddress: 发送 $bytesSent 字节数据');
      GlobalLogger.logInfo('已成功向 $broadcastAddress: 发送 $bytesSent 字节数据');
    } catch (e) {
      SimplePopup.toast(e.toString());
    }
  }

  @override
  Stream<RtcEvent> get eventStream => _onEventStreamController.stream;

  @override
  Stream<Uint8List> get receiveStream => _onDataStreamController.stream;

  @override
  Future<List<String>> getRemotePeers() {
    throw UnimplementedError();
  }
}
