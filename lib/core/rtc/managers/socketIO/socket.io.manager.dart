import 'dart:async';
import 'dart:convert';
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
    _socket!.listen((RawSocketEvent event) {
      switch (event) {
        case RawSocketEvent.read:
          // 核心：循环耗尽内核缓冲区
          Datagram? datagram;
          while ((datagram = _socket!.receive()) != null) {}
          break;

        case RawSocketEvent.write:
          // ℹ️ 状态通知：发送缓冲区可写
          // 如果主动调用了 writeEventsEnabled = true，此时可执行发送操作
          // 发送完成后建议关闭写监听，避免反复触发
          GlobalLogger.logInfo("Socket 可写（正常状态）");
          // 例如： _socket!.send(data, address, port);
          // _socket!.writeEventsEnabled = false; // 关闭写监听
          break;

        case RawSocketEvent.readClosed:
          // ❌ 错误提示：UDP 下不应收到此事件
          GlobalLogger.logError("错误：收到 readClosed 事件，UDP 无连接特性下此事件不合理");
          // 通常表示对端异常关闭或底层错误
          // 可考虑记录日志、关闭 socket 或重连
          _socket!.close();
          break;

        case RawSocketEvent.closed:
          // ⚠️ 连接结束提示：socket 已关闭
          GlobalLogger.logError("Socket 已关闭（主动或被动）");
          // 清理资源，通知上层断开
          _socket = null;
          break;
      }
    });
  }

  Future<void> connect(String remotePeerAddress) async {}

  void handleData(Datagram datagram) {
    // 1. 获取原始字节数据 (Uint8List)
    Uint8List rawData = datagram.data;

    // 2. 解析数据（假设对端传的是 UTF-8 字符串）
    String message = utf8.decode(rawData);

    // 3. 获取对端的 IP 和端口（用于回复或识别来源）
    InternetAddress senderAddress = datagram.address;
    int senderPort = datagram.port;

    // 4. 打印或处理业务逻辑
    print('收到来自 $senderAddress:$senderPort 的数据: $message');

    // 5. 如果需要，在这里调用 _socket!.send() 进行回复
  }

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
      final broadcastAddress = InternetAddress(remotePeerAddress);
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
