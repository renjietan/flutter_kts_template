import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_address.dart';
import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_config.dart';
import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_ffi.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.type.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';
import 'package:flutter_kts_template/logger/logger.dart';

/// Windows WinUSB 通信管理器。
///
/// 基于 Windows WinUSB API（通过 FFI 直接调用系统 DLL），实现对 WinUSB 类
/// 设备（如 VID_0525 / PID_A4A1 / MI_02 的自定义存储设备）的枚举、连接与收发。
///
/// 实现思路完全对齐根目录 `go.md` 的成功案例：
/// - **枚举**：从注册表 `SYSTEM\CurrentControlSet\Enum\USB` 读取 `Service=WINUSB`
///   的设备，用 `DeviceInterfaceGUIDs` 构造路径，并以 `canOpenAsWinUsb` 验证。
/// - **连接**：`CreateFile`(FILE_FLAG_OVERLAPPED) + `WinUsb_Initialize`。
/// - **端点**：`WinUsb_QueryInterfaceSettings` + `WinUsb_QueryPipe`，按 bit7 区分 IN/OUT。
/// - **超时**：`WinUsb_SetPipePolicy(PIPE_TRANSFER_TIMEOUT)` 对 IN/OUT 分别设置。
/// - **收发**：`WinUsb_WritePipe` / `WinUsb_ReadPipe` / `WinUsb_FlushPipe`。
///
/// 设备地址采用 `vid:pid:interface` 格式（见 [WinUsbAddress]），
/// 例如 `0x0525:0xA4A1:2`。
class WinUsbManager implements RtcAbstract {
  static final WinUsbManager _instance = WinUsbManager._internal();

  factory WinUsbManager() => _instance;

  WinUsbManager._internal();

  WinUsbConfig _config = const WinUsbConfig();

  final Map<String, WinUsbDeviceInfo> _devices = {};

  String? _connectedAddress;
  int _deviceHandle = 0;
  int _interfaceHandle = 0;
  int _inPipeId = 0;
  int _outPipeId = 0;

  bool _initialized = false;
  bool _connected = false;

  Timer? _receiveTimer;
  bool _receiving = false;

  final StreamController<RtcReceive> _onDataStreamController =
      StreamController<RtcReceive>.broadcast();
  final StreamController<RtcEvent> _onEventController =
      StreamController<RtcEvent>.broadcast();

  bool get hasConnection => _connected;

  void setConfig(WinUsbConfig config) {
    _config = config;
  }

  @override
  Future<List<String>> getRemotePeers() async {
    return _devices.keys.toList();
  }

  /// 刷新设备列表（对齐 go.md 的 ListDevices：注册表枚举为主，SetupDi 为兜底）。
  Future<void> _refreshDevices() async {
    try {
      var devices = await listWinUsbDevicesFromRegistry();

      if (devices.isEmpty) {
        GlobalLogger.logInfo('注册表枚举无结果，回退到 SetupDi 枚举');
        devices = await enumerateWinUsbDevices();
      }

      _devices.clear();
      for (final device in devices) {
        final address = WinUsbAddress.fromDeviceInfo(device).toString();
        _devices[address] = device;
        GlobalLogger.logInfo('WinUSB 设备: $address -> ${device.devicePath}');
      }
      GlobalLogger.logInfo('WinUSB 枚举完成，发现 ${_devices.length} 个设备');
    } catch (e) {
      GlobalLogger.logError('WinUSB 枚举失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> init(String localPeerAddress) async {
    try {
      if (_initialized) {
        await disconnect();
      }
      _devices.clear();
      await _refreshDevices();
      _initialized = true;
      _onEventController.sink.add(RtcEvent(type: RtcEventType.created));
    } catch (e) {
      GlobalLogger.logError('WinUSB 初始化失败: $e');
      _onEventController.sink.add(
        RtcEvent(type: RtcEventType.error, msg: e.toString()),
      );
    }
  }

  @override
  Future<void> connect(String remotePeerAddress) async {
    try {
      final address = WinUsbAddress.fromString(remotePeerAddress);
      final addressStr = address.toString();

      if (_connected && _connectedAddress == addressStr) {
        GlobalLogger.logInfo('WinUSB 设备已连接: $addressStr');
        return;
      }

      if (_connected) {
        await _doDisconnect();
      }

      WinUsbDeviceInfo? deviceInfo = _devices[addressStr];
      if (deviceInfo == null) {
        await _refreshDevices();
        deviceInfo = _devices[addressStr];
      }

      if (deviceInfo == null) {
        GlobalLogger.logError('未找到 WinUSB 设备: $addressStr');
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.error,
            remotePeer: addressStr,
            msg: '未找到 WinUSB 设备',
          ),
        );
        return;
      }

      // 对齐 go.md 的 Open：CreateFile + WinUsb_Initialize
      // 路径已在枚举阶段通过 canOpenAsWinUsb 验证，可直接 Initialize
      GlobalLogger.logInfo('正在打开设备: ${deviceInfo.devicePath}');
      _deviceHandle = openDevice(deviceInfo.devicePath);
      GlobalLogger.logInfo('设备句柄已打开: $_deviceHandle');

      _interfaceHandle = winUsbInitialize(_deviceHandle);
      GlobalLogger.logInfo('WinUSB 接口初始化成功: $_interfaceHandle');

      // 对齐 go.md 的 queryEndpoints：查询 alternate setting 0
      final settings = queryInterfaceSettings(_interfaceHandle, 0);
      GlobalLogger.logInfo(
        '接口 ${settings.interfaceNumber} - 端点数量: ${settings.numEndpoints}',
      );

      final pipes = listPipes(_interfaceHandle, 0);
      GlobalLogger.logInfo('发现 ${pipes.length} 个管道');

      for (final pipe in pipes) {
        final pipeId = pipe.pipeId;
        final pipeType = pipe.pipeType;
        if (pipeType == PIPE_TYPE_BULK ||
            pipeType == PIPE_TYPE_INTERRUPT ||
            pipeType == PIPE_TYPE_ISOCHRONOUS) {
          // 对齐 go.md：PipeId & 0x80 != 0 为 IN，否则为 OUT
          if (isInPipe(pipeId)) {
            _inPipeId = pipeId;
            GlobalLogger.logInfo(
              'IN 管道: id=$pipeId, type=$pipeType, '
              'maxPacketSize=${pipe.maximumPacketSize}',
            );
          } else {
            _outPipeId = pipeId;
            GlobalLogger.logInfo(
              'OUT 管道: id=$pipeId, type=$pipeType, '
              'maxPacketSize=${pipe.maximumPacketSize}',
            );
          }
        }
      }

      // 对齐 go.md：EpOut 或 EpIn 未找到即报错
      if (_outPipeId == 0 || _inPipeId == 0) {
        GlobalLogger.logError(
          '端点未找到: EpOut=0x${_outPipeId.toRadixString(16)} '
          'EpIn=0x${_inPipeId.toRadixString(16)}',
        );
        _cleanupHandles();
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.error,
            remotePeer: addressStr,
            msg: '端点未找到: EpOut=0x${_outPipeId.toRadixString(16)} '
                'EpIn=0x${_inPipeId.toRadixString(16)}',
          ),
        );
        return;
      }

      // 对齐 go.md 的 setPipeTimeout：IN/OUT 分别设置 PIPE_TRANSFER_TIMEOUT
      setPipeTimeout(_interfaceHandle, _outPipeId, _config.writeTimeoutMs);
      setPipeTimeout(_interfaceHandle, _inPipeId, _config.readTimeoutMs);
      GlobalLogger.logInfo(
        '管道超时已设置: OUT=${_config.writeTimeoutMs}ms, IN=${_config.readTimeoutMs}ms',
      );

      _connected = true;
      _connectedAddress = addressStr;

      _startReceiveLoop();

      GlobalLogger.logInfo('WinUSB 设备连接成功: $addressStr');
      _onEventController.sink.add(
        RtcEvent(
          type: RtcEventType.created,
          remotePeer: addressStr,
          msg: 'WinUSB 设备连接成功',
        ),
      );
    } catch (e) {
      GlobalLogger.logError('WinUSB 连接异常: $e');
      _cleanupHandles();
      _onEventController.sink.add(
        RtcEvent(type: RtcEventType.error, msg: e.toString()),
      );
    }
  }

  /// 启动接收轮询循环。
  ///
  /// go.md 在 goroutine 中阻塞式 `Read`；Dart 单 isolate 不能长时间阻塞，
  /// 因此以 [WinUsbConfig.readTimeoutMs] 为间隔轮询。IN 管道的
  /// PIPE_TRANSFER_TIMEOUT 同样设为 readTimeoutMs，无数据时读取在此时长内返回，
  /// 不会长时间阻塞事件循环。
  void _startReceiveLoop() {
    if (_receiveTimer != null) return;

    _receiveTimer = Timer.periodic(
      Duration(milliseconds: _config.readTimeoutMs),
      (_) => _readData(),
    );
  }

  void _stopReceiveLoop() {
    _receiveTimer?.cancel();
    _receiveTimer = null;
  }

  Future<void> _readData() async {
    if (!_connected || _receiving || _inPipeId == 0) return;
    _receiving = true;

    try {
      final data = winUsbReadPipe(
        _interfaceHandle,
        _inPipeId,
        _config.readBufferSize,
      );

      if (data.isNotEmpty) {
        GlobalLogger.logDebug('WinUSB 收到 ${data.length} 字节');
        _onDataStreamController.sink.add(
          RtcReceive(address: _connectedAddress ?? '', data: data, port: 0),
        );
      }
      // 数据为空（超时无数据）：静默继续轮询，不发送错误事件
    } catch (e) {
      // 读取超时/无数据属于正常轮询行为，仅记录调试日志，不抛错误事件
      GlobalLogger.logDebug('WinUSB 读取无数据: $e');
    } finally {
      _receiving = false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _doDisconnect();
    _devices.clear();
    _initialized = false;
  }

  Future<void> _doDisconnect() async {
    _stopReceiveLoop();

    if (_connected) {
      _connected = false;
      final address = _connectedAddress;

      _cleanupHandles();

      if (address != null) {
        _onEventController.sink.add(
          RtcEvent(
            type: RtcEventType.disConnect,
            remotePeer: address,
            msg: 'WinUSB 设备已断开',
          ),
        );
      }
      _connectedAddress = null;
      GlobalLogger.logInfo('WinUSB 设备已断开');
    }
  }

  void _cleanupHandles() {
    if (_interfaceHandle != 0) {
      try {
        winUsbFree(_interfaceHandle);
      } catch (e) {
        GlobalLogger.logError('释放 WinUSB 接口句柄异常: $e');
      }
      _interfaceHandle = 0;
    }
    if (_deviceHandle != 0) {
      try {
        closeDevice(_deviceHandle);
      } catch (e) {
        GlobalLogger.logError('关闭设备句柄异常: $e');
      }
      _deviceHandle = 0;
    }
    _inPipeId = 0;
    _outPipeId = 0;
  }

  @override
  Future<void> write(Uint8List data, String remotePeerAddress) async {
    try {
      int outPipeId;
      if (remotePeerAddress.isNotEmpty) {
        final address = WinUsbAddress.fromString(remotePeerAddress);
        final addressStr = address.toString();

        if (_connectedAddress != addressStr) {
          GlobalLogger.logInfo('自动连接设备: $addressStr');
          await connect(remotePeerAddress);
        }
        if (!_connected || _connectedAddress != addressStr) {
          GlobalLogger.logError('WinUSB 未连接到目标设备: $addressStr');
          _onEventController.sink.add(
            RtcEvent(
              type: RtcEventType.error,
              remotePeer: addressStr,
              msg: 'WinUSB 未连接',
            ),
          );
          return;
        }
        outPipeId = _outPipeId;
      } else {
        if (!_connected) {
          GlobalLogger.logError('无可用的 WinUSB 连接，写入失败');
          _onEventController.sink.add(
            RtcEvent(type: RtcEventType.error, msg: '无可用的 WinUSB 连接'),
          );
          return;
        }
        outPipeId = _outPipeId;
      }

      if (outPipeId == 0) {
        GlobalLogger.logError('WinUSB 无可用的 OUT 管道');
        _onEventController.sink.add(
          RtcEvent(type: RtcEventType.error, msg: '无可用的 OUT 管道'),
        );
        return;
      }

      // 对齐 go.md 的 Write: WinUsb_WritePipe
      final bytesWritten = winUsbWritePipe(_interfaceHandle, outPipeId, data);
      GlobalLogger.logDebug('WinUSB 写入 $bytesWritten 字节');
    } catch (e) {
      GlobalLogger.logError('WinUSB 写入异常: $e');
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
