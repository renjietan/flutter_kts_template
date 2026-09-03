import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_manager.dart';

/// 注钥枪 USB Host（裸 Bulk）管理器（Android 端）。
///
/// 与 `android.usb.manager.dart` 的串口管理器不同，本类面向
/// Vendor Specific Class（bInterfaceClass=255）的裸 Bulk 设备：
///   - 接口号 2
///   - EP5 IN (0x85)：接收
///   - EP4 OUT (0x04)：发送
///
/// 底层由 Android 原生 `MainActivity`（Kotlin）通过 `UsbManager` /
/// `UsbDeviceConnection.bulkTransfer` 实现，经 MethodChannel + EventChannel
/// 暴露给 Dart。
class AndroidUsbBulkManager implements KeyLoaderUsbBulkManager {
  AndroidUsbBulkManager._();

  static final AndroidUsbBulkManager instance = AndroidUsbBulkManager._();

  static const MethodChannel _channel = MethodChannel(
    'com.hytera.cpd/usb_host',
  );
  static const EventChannel _events = EventChannel(
    'com.hytera.cpd/usb_host/events',
  );
  static const EventChannel _disconnectEvents = EventChannel(
    'com.hytera.cpd/usb_host/disconnected',
  );

  Stream<Uint8List>? _dataStream;
  Stream<void>? _disconnectStream;

  /// 当前是否有目标注钥枪的 USB 权限。
  @override
  Future<bool> hasPermission() async {
    final value = await _channel.invokeMethod<bool>('hasPermission');
    return value ?? false;
  }

  /// 请求 USB 权限（弹出系统授权对话框）。
  @override
  Future<bool> requestPermission() async {
    final value = await _channel.invokeMethod<bool>('requestPermission');
    return value ?? false;
  }

  /// 设备拔出事件。
  ///
  /// Android 原生侧通过 `ACTION_USB_DEVICE_DETACHED` 上报后，再向该流发出事件。
  @override
  Stream<void> get onDisconnected => _disconnectStream ??= _disconnectEvents
      .receiveBroadcastStream()
      .map((_) {});

  /// 连接注钥枪：打开设备、claim 接口、启动读线程。
  @override
  Future<bool> connect() async {
    final value = await _channel.invokeMethod<bool>('connect');
    return value ?? false;
  }

  /// 是否已连接。
  @override
  Future<bool> isConnected() async {
    final value = await _channel.invokeMethod<bool>('isConnected');
    return value ?? false;
  }

  /// 通过 bulk OUT 发送字节，返回实际写入字节数，-1 表示失败。
  @override
  Future<int> write(Uint8List data) async {
    final value = await _channel.invokeMethod<int>('write', data);
    return value ?? -1;
  }

  /// 断开连接。
  @override
  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
    _dataStream = null;
    _disconnectStream = null;
  }

  /// 监听 bulk IN 收到的数据。
  @override
  Stream<Uint8List> listenData() {
    return _dataStream ??= _events.receiveBroadcastStream().map((event) {
      if (event is Uint8List) return event;
      if (event is List<int>) return Uint8List.fromList(event);
      return Uint8List(0);
    });
  }
}
