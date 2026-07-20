import 'dart:convert';
import 'dart:io';

class SocketIOManager {
  static late final RawDatagramSocket? socket;
  static Future<void> init({int targetPort = 3333}) async {
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      // 启用广播权限
      socket?.broadcastEnabled = true;
    } catch (e) {
      print('发送广播失败: $e');
    } finally {
      // 5. 释放资源
      socket?.close();
    }
  }

  static Future<void> send() async {
    final broadcastAddress = InternetAddress('255.255.255.255');
    final data = utf8.encode("admin");
    int? bytesSent = socket?.send(data, broadcastAddress, 3333);
    print('已成功向 $broadcastAddress: 发送 $bytesSent 字节数据');
  }
}
