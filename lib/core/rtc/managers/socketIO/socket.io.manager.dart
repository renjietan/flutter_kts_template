import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';
import 'package:flutter_kts_template/logger/logger.dart';

class SocketIOManager implements RtcAbstract {
  SocketIOManager._internal();

  static final SocketIOManager _instance = SocketIOManager._internal();

  RawDatagramSocket? _socket;
  int _localPort = 0;
  int _remotePort = 3333;

  final StreamController<RtcReceive> _onDataStreamController =
      StreamController<RtcReceive>.broadcast();
  final StreamController<RtcEvent> _onEventStreamController =
      StreamController<RtcEvent>.broadcast();

  factory SocketIOManager() {
    return _instance;
  }

  bool get isConnected => _socket != null;

  /// CPDS/CPDC 使用固定收发端口。
  ///
  /// [localPort] 为空时保持原有行为（随机端口）。
  /// [remotePort] 为空时保持原有行为（3333）。
  void configure({int? localPort, int? remotePort}) {
    if (localPort != null) {
      _localPort = localPort;
    }
    if (remotePort != null) {
      _remotePort = remotePort;
    }
  }

  @override
  Future<void> init(String localPeerAddress) async {
    await disconnect();
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _localPort);
    // 启用广播权限
    _socket!.broadcastEnabled = true;
    _socket!.listen((RawSocketEvent event) {
      switch (event) {
        case RawSocketEvent.read:
          // 核心：循环耗尽内核缓冲区
          Datagram? datagram;
          while ((datagram = _socket!.receive()) != null) {
            Uint8List data = datagram?.data ?? Uint8List(0);
            if (data.isNotEmpty) {
              _onDataStreamController.sink.add(
                RtcReceive(
                  address: datagram!.address.address,
                  data: data,
                  port: datagram.port,
                ),
              );
            }
          }
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

  @override
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
      final broadcastAddress = InternetAddress(remotePeerAddress);
      // 为了获取发送字节数，使用 send 方法
      int? bytesSent = _socket?.send(data, broadcastAddress, _remotePort);
      GlobalLogger.logInfo(
        '已成功向 $broadcastAddress:$_remotePort 发送 $bytesSent 字节数据',
      );
    } catch (e) {
      SimplePopup.toast(e.toString());
    }
  }

  @override
  Stream<RtcEvent> get eventStream => _onEventStreamController.stream;

  @override
  Stream<RtcReceive> get receiveStream => _onDataStreamController.stream;

  @override
  Future<List<String>> getRemotePeers() {
    throw UnimplementedError();
  }
}
