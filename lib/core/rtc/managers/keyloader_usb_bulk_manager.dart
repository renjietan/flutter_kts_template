import 'dart:typed_data';

/// keyLoader 导出使用的跨平台裸 Bulk USB 接口。
abstract class KeyLoaderUsbBulkManager {
  Future<bool> isConnected();

  Future<bool> hasPermission();

  Future<bool> requestPermission();

  Future<bool> connect();

  Future<int> write(Uint8List data);

  Stream<Uint8List> listenData();

  /// 设备被拔出（或连接异常断开）时发出一次事件。
  Stream<void> get onDisconnected;

  /// 清空 USB 输入端点中尚未读取的残留数据。
  Future<void> flushInput();

  /// 短暂订阅输入流，丢弃已经到达的残留数据。
  Future<void> drainInput({
    Duration duration = const Duration(milliseconds: 250),
  });

  Future<void> disconnect();
}
