import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/android-usb/android.usb.address.dart';
import 'package:flutter_kts_template/core/rtc/managers/android-usb/android.usb.config.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.type.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:usb_serial/usb_serial.dart';

/// Android USB 串口通信管理器。
///
/// 基于 `usb_serial` 插件（底层为 felHR85/UsbSerial），支持 FTDI、CDC、CH34x、
/// CP210x、PL2303 等常见 USB 转串口芯片，实现 [RtcAbstract] 接口。
///
/// 设备地址采用 `vid:pid` 格式（见 [AndroidUsbAddress]），例如 `1027:24577`。
///
/// 典型用法：
/// ```dart
/// final manager = AndroidUsbManager();
/// manager.eventStream.listen((e) => print(e));
/// manager.receiveStream.listen((d) => print(d.data));
/// await manager.init('');
/// await manager.connect('1027:24577');
/// await manager.write(Uint8List.fromList([0x10, 0x00]), '1027:24577');
/// ```
class AndroidUsbManager implements RtcAbstract {
  static final AndroidUsbManager _instance = AndroidUsbManager._internal();

  factory AndroidUsbManager() => _instance;

  AndroidUsbManager._internal();

  /// 串口参数，连接建立时应用到对应 [UsbPort]。
  AndroidUsbConfig _config = const AndroidUsbConfig();

  /// 已发现的设备：address -> UsbDevice。
  final Map<String, UsbDevice> _devices = {};

  /// 已连接的端口：address -> UsbPort。
  final Map<String, UsbPort> _ports = {};

  /// 输入流订阅：address -> StreamSubscription。
  final Map<String, StreamSubscription<Uint8List>> _inputSubscriptions = {};

  /// USB 设备插拔事件订阅。
  StreamSubscription<UsbEvent>? _usbEventSubscription;

  bool _initialized = false;

  final StreamController<RtcReceive> _onDataStreamController =
      StreamController<RtcReceive>.broadcast();
  final StreamController<RtcEvent> _onEventController =
      StreamController<RtcEvent>.broadcast();

  /// 当前是否已连接任意设备。
  bool get hasConnection => _ports.isNotEmpty;

  /// 更新串口参数（在 [connect] 之前调用）。
  void setConfig(AndroidUsbConfig config) {
    _config = config;
  }

  /// 枚举当前已插入的 USB 设备，刷新 [_devices] 缓存。
  Future<void> _refreshDevices() async {
    final devices = await UsbSerial.listDevices();
    for (final device in devices) {
      final address = AndroidUsbAddress.fromDevice(device).toString();
      _devices[address] = device;
    }
  }

  @override
  Future<List<String>> getRemotePeers() async {
    return _ports.keys.toList();
  }

  /// 初始化 USB 子系统：枚举当前设备并监听插拔事件。
  ///
  /// [localPeerAddress] 对 USB 无意义（USB 为主从直连，无本地地址概念），
  /// 保留该参数仅为符合 [RtcAbstract] 接口约定。
  @override
  Future<void> init(String localPeerAddress) async {
    try {
      if (_initialized) {
        await disconnect();
      }
      _devices.clear();
      await _refreshDevices();
      GlobalLogger.logInfo('USB 初始化完成，发现 ${_devices.length} 个设备');

      _usbEventSubscription = UsbSerial.usbEventStream?.listen(_onUsbEvent);

      _initialized = true;
      _onEventController.sink.add(RtcEvent(type: RtcEventType.created));
    } catch (e) {
      GlobalLogger.logError('USB 初始化失败: $e');
      _onEventController.sink.add(
        RtcEvent(type: RtcEventType.error, msg: e.toString()),
      );
    }
  }

  /// 处理 USB 设备插拔事件。
  void _onUsbEvent(UsbEvent event) {
    final device = event.device;
    final address =
        device != null
            ? AndroidUsbAddress.fromDevice(device).toString()
            : null;

    if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
      if (device != null && address != null) {
        _devices[address] = device;
        GlobalLogger.logInfo('USB 设备插入: $address');
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.info,
            remotePeer: address,
            msg: 'USB 设备插入: $address',
          ),
        );
      }
    } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
      if (address != null) {
        _devices.remove(address);
        GlobalLogger.logInfo('USB 设备拔出: $address');
        // 设备拔出后主动关闭对应端口，避免悬空写入
        unawaited(_closePort(address));
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.disConnect,
            remotePeer: address,
            msg: 'USB 设备拔出: $address',
          ),
        );
      }
    }
  }

  /// 连接到指定 USB 串口设备。
  ///
  /// [remotePeerAddress] 格式为 `vid:pid`（见 [AndroidUsbAddress]），例如 `1027:24577`。
  /// 连接成功后自动应用 [_config] 中的串口参数，并订阅输入流。
  @override
  Future<void> connect(String remotePeerAddress) async {
    try {
      final addressStr = AndroidUsbAddress.fromString(
        remotePeerAddress,
      ).toString();

      // 已连接则直接返回
      if (_ports.containsKey(addressStr)) {
        GlobalLogger.logInfo('USB 设备已连接: $addressStr');
        return;
      }

      // 缓存中未找到则重新枚举一次设备
      UsbDevice? device = _devices[addressStr];
      if (device == null) {
        await _refreshDevices();
        device = _devices[addressStr];
      }
      if (device == null) {
        GlobalLogger.logError('未找到 USB 设备: $addressStr');
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.error,
            remotePeer: addressStr,
            msg: '未找到 USB 设备: $addressStr',
          ),
        );
        return;
      }

      // 创建并打开端口
      final UsbPort? port = await device.create();
      if (port == null) {
        GlobalLogger.logError('创建 USB 端口失败: $addressStr');
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.error,
            remotePeer: addressStr,
            msg: '创建 USB 端口失败',
          ),
        );
        return;
      }

      final bool opened = await port.open();
      if (!opened) {
        GlobalLogger.logError('打开 USB 端口失败: $addressStr');
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.error,
            remotePeer: addressStr,
            msg: '打开 USB 端口失败',
          ),
        );
        return;
      }

      // 应用串口参数
      await port.setPortParameters(
        _config.baudRate,
        _config.dataBits,
        _config.stopBits,
        _config.parity,
      );
      await port.setDTR(_config.dtr);
      await port.setRTS(_config.rts);
      if (_config.flowControl != null) {
        await port.setFlowControl(_config.flowControl!);
      }

      // 订阅输入流：将收到的字节转发到 receiveStream
      final subscription = port.inputStream?.listen(
        (Uint8List data) {
          if (data.isNotEmpty) {
            _onDataStreamController.sink.add(
              RtcReceive(address: addressStr, data: data, port: 0),
            );
          }
        },
        onError: (Object e) {
          GlobalLogger.logError('USB 读取错误: $e');
          _onEventController.sink.add(
            RtcEvent(
              type: RtcEventType.error,
              remotePeer: addressStr,
              msg: e.toString(),
            ),
          );
        },
      );
      if (subscription != null) {
        _inputSubscriptions[addressStr] = subscription;
      }

      _ports[addressStr] = port;
      GlobalLogger.logInfo('USB 设备连接成功: $addressStr');
      _onEventController.sink.add(
        RtcEvent(
          type: RtcEventType.created,
          remotePeer: addressStr,
          msg: 'USB 设备连接成功',
        ),
      );
    } catch (e) {
      GlobalLogger.logError('USB 连接异常: $e');
      _onEventController.sink.add(
        RtcEvent(type: RtcEventType.error, msg: e.toString()),
      );
    }
  }

  /// 关闭指定地址的端口并清理其输入流订阅。
  Future<void> _closePort(String addressStr) async {
    await _inputSubscriptions[addressStr]?.cancel();
    _inputSubscriptions.remove(addressStr);

    final port = _ports.remove(addressStr);
    if (port != null) {
      try {
        await port.close();
      } catch (e) {
        GlobalLogger.logError('关闭 USB 端口异常: $e');
      }
      _onEventController.sink.add(
        RtcEvent(type: RtcEventType.closed, remotePeer: addressStr),
      );
    }
  }

  /// 断开所有 USB 连接并释放资源（保留串口参数配置）。
  @override
  Future<void> disconnect() async {
    final addresses = _ports.keys.toList();
    for (final address in addresses) {
      await _closePort(address);
    }
    await _usbEventSubscription?.cancel();
    _usbEventSubscription = null;
    _devices.clear();
    _initialized = false;
  }

  /// 向指定 USB 设备写入数据。
  ///
  /// [remotePeerAddress] 格式为 `vid:pid`。若该设备尚未连接，会自动发起 [connect]。
  /// 若 [remotePeerAddress] 为空且当前仅有一个连接，则写入该连接。
  @override
  Future<void> write(Uint8List data, String remotePeerAddress) async {
    try {
      UsbPort? port;
      if (remotePeerAddress.isNotEmpty) {
        final addressStr = AndroidUsbAddress.fromString(
          remotePeerAddress,
        ).toString();
        port = _ports[addressStr];
        // 未连接则自动连接，参考 SocketIOManager 的处理方式
        if (port == null) {
          await connect(remotePeerAddress);
          port = _ports[addressStr];
        }
      } else if (_ports.length == 1) {
        port = _ports.values.first;
      }

      if (port == null) {
        GlobalLogger.logError('无可用的 USB 连接，写入失败');
        _onEventController.sink.add(
          RtcEvent(type: RtcEventType.error, msg: '无可用的 USB 连接'),
        );
        return;
      }

      await port.write(data);
    } catch (e) {
      GlobalLogger.logError('USB 写入异常: $e');
      _onEventController.sink.add(
        RtcEvent(type: RtcEventType.error, msg: e.toString()),
      );
    }
  }

  @override
  Stream<RtcReceive> get receiveStream => _onDataStreamController.stream;

  @override
  Stream<RtcEvent> get eventStream => _onEventController.stream;
}
