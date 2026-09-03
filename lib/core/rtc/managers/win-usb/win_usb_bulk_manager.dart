import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_kts_template/core/rtc/managers/keyloader_usb_bulk_manager.dart';
import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_ffi.dart';
import 'package:flutter_kts_template/logger/logger.dart';

/// Windows 注钥枪裸 Bulk USB 管理器。
///
/// 与 [WinUsbManager] 不同，本类面向 keyLoader 的 WinUSB 复合设备接口：
///   - VID_1D6B / PID_0104 / MI_02
///   - DeviceInterfaceGUID = {fed3a0be-9515-4920-812b-51d602e63752}
///
/// 读数据采用 overlapped + event 的异步读，并在独立 isolate 中等待完成事件，
/// 避免在主 isolate 上轮询或阻塞。提供与 [AndroidUsbBulkManager] 一致的
/// connect / write / disconnect / listenData 接口。
class WinUsbBulkManager implements KeyLoaderUsbBulkManager {
  WinUsbBulkManager._();

  static final WinUsbBulkManager instance = WinUsbBulkManager._();

  static const int _vid = 0x1D6B;
  static const int _pid = 0x0104;
  static const int _interfaceNumber = 2;
  static const String _interfaceGuid = 'fed3a0be-9515-4920-812b-51d602e63752';

  static const int _readBufferSize = 512;
  static const int _writeTimeoutMs = 3000;

  int _deviceHandle = 0;
  int _interfaceHandle = 0;
  int _inPipeId = 0;
  int _outPipeId = 0;

  Isolate? _readIsolate;
  ReceivePort? _readPort;
  StreamSubscription<dynamic>? _readSub;
  int _readEvent = 0;
  int _shutdownEvent = 0;
  Completer<void> _readLoopExited = Completer<void>();

  bool _connected = false;
  Future<void>? _teardownFuture;

  final StreamController<Uint8List> _dataController =
      StreamController<Uint8List>.broadcast();
  final StreamController<void> _disconnectedController =
      StreamController<void>.broadcast();

  @override
  Future<bool> isConnected() async => _connected;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<void> get onDisconnected => _disconnectedController.stream;

  @override
  Future<bool> connect() async {
    if (_connected) return true;
    try {
      final path = findWinUsbDevicePathByDeviceClasses(
        vid: _vid,
        pid: _pid,
        interfaceNumber: _interfaceNumber,
        interfaceGuid: _interfaceGuid,
      );
      if (path == null) {
        GlobalLogger.logError(
          'WinUsbBulkManager: key loader WinUSB interface not found',
        );
        return false;
      }

      _deviceHandle = openDevice(path);
      _interfaceHandle = winUsbInitialize(_deviceHandle);

      var found = false;
      for (var interfaceIndex = 0; interfaceIndex < 8; interfaceIndex++) {
        final settings = queryInterfaceSettings(
          _interfaceHandle,
          interfaceIndex,
        );
        final pipes = listPipes(_interfaceHandle, interfaceIndex);
        for (final pipe in pipes) {
          if (pipe.pipeType == PIPE_TYPE_BULK) {
            if (isInPipe(pipe.pipeId)) {
              _inPipeId = pipe.pipeId;
            } else {
              _outPipeId = pipe.pipeId;
            }
          }
        }
        GlobalLogger.logInfo(
          'WinUsbBulkManager: interface=$interfaceIndex '
          'num=${settings.interfaceNumber} '
          'endpoints=${settings.numEndpoints} '
          'inPipe=0x${_inPipeId.toRadixString(16)} '
          'outPipe=0x${_outPipeId.toRadixString(16)}',
        );
        if (_inPipeId != 0 && _outPipeId != 0) {
          found = true;
          break;
        }
      }

      if (!found) {
        GlobalLogger.logError(
          'WinUsbBulkManager: bulk endpoints not found '
          'in=0x${_inPipeId.toRadixString(16)} '
          'out=0x${_outPipeId.toRadixString(16)}',
        );
        _cleanupHandles();
        return false;
      }

      setPipeTimeout(_interfaceHandle, _outPipeId, _writeTimeoutMs);

      _connected = true;
      if (!_startReadLoop()) {
        GlobalLogger.logError('WinUsbBulkManager: failed to start read loop');
        _connected = false;
        _cleanupHandles();
        return false;
      }
      GlobalLogger.logInfo('WinUsbBulkManager: connected');
      return true;
    } catch (e) {
      GlobalLogger.logError('WinUsbBulkManager: connect error $e');
      _cleanupHandles();
      return false;
    }
  }

  @override
  Future<int> write(Uint8List data) async {
    if (!_connected || _outPipeId == 0) return -1;
    try {
      return winUsbWritePipe(_interfaceHandle, _outPipeId, data);
    } on WinUsbError catch (e) {
      GlobalLogger.logError('WinUsbBulkManager: write error $e');
      if (isUsbDeviceGoneError(e.errorCode)) {
        _handleDisconnected();
      }
      return -1;
    } catch (e) {
      GlobalLogger.logError('WinUsbBulkManager: write error $e');
      return -1;
    }
  }

  @override
  Stream<Uint8List> listenData() => _dataController.stream;

  @override
  Future<void> disconnect() async {
    _connected = false;
    await _teardown();
  }

  bool _startReadLoop() {
    if (_readPort != null) return true;
    try {
      final readEvent = fCreateEventW(nullptr, 1, 0, nullptr);
      final shutdownEvent = fCreateEventW(nullptr, 1, 0, nullptr);
      if (readEvent == 0 || shutdownEvent == 0) {
        if (readEvent != 0) fCloseHandle(readEvent);
        if (shutdownEvent != 0) fCloseHandle(shutdownEvent);
        return false;
      }
      _readEvent = readEvent;
      _shutdownEvent = shutdownEvent;

      final port = ReceivePort();
      _readPort = port;
      _readLoopExited = Completer<void>();
      _readSub = port.listen(_onReadMessage);

      final context = _WinUsbReadContext(
        interfaceHandle: _interfaceHandle,
        inPipeId: _inPipeId,
        bufferSize: _readBufferSize,
        readEvent: readEvent,
        shutdownEvent: shutdownEvent,
        sendPort: port.sendPort,
      );

      Isolate.spawn(_winUsbReadLoop, context).then(
        (isolate) {
          _readIsolate = isolate;
        },
        onError: (Object error, StackTrace stackTrace) {
          GlobalLogger.logError(
            'WinUsbBulkManager: read isolate spawn error $error',
          );
        },
      );
      return true;
    } catch (e) {
      GlobalLogger.logError('WinUsbBulkManager: start read loop error $e');
      return false;
    }
  }

  Future<void> _stopReadLoop() async {
    final shutdownEvent = _shutdownEvent;
    final isolate = _readIsolate;
    final port = _readPort;
    final sub = _readSub;

    _readIsolate = null;
    _readPort = null;
    _readSub = null;

    if (shutdownEvent != 0) {
      fSetEvent(shutdownEvent);
    }

    if (port != null) {
      try {
        await _readLoopExited.future.timeout(const Duration(seconds: 2));
      } catch (_) {
        isolate?.kill(priority: Isolate.immediate);
      }
    }

    await sub?.cancel();
    port?.close();

    if (_readEvent != 0) {
      fCloseHandle(_readEvent);
      _readEvent = 0;
    }
    if (_shutdownEvent != 0) {
      fCloseHandle(_shutdownEvent);
      _shutdownEvent = 0;
    }
  }

  void _onReadMessage(dynamic message) {
    if (message is! Map) return;
    final type = message['type'];
    if (type == 'data') {
      final bytes = message['bytes'];
      if (bytes is Uint8List &&
          bytes.isNotEmpty &&
          !_dataController.isClosed) {
        _dataController.add(bytes);
      }
    } else if (type == 'disconnected') {
      _handleDisconnected();
    } else if (type == 'error') {
      GlobalLogger.logWarn(
        'WinUsbBulkManager: read error ${message['message']}',
      );
    } else if (type == 'done') {
      if (!_readLoopExited.isCompleted) {
        _readLoopExited.complete();
      }
    }
  }

  void _handleDisconnected() {
    if (!_connected) return;
    _connected = false;
    unawaited(_teardown());
    if (!_disconnectedController.isClosed) {
      _disconnectedController.add(null);
    }
    GlobalLogger.logInfo('WinUsbBulkManager: device disconnected');
  }

  Future<void> _teardown() {
    final existing = _teardownFuture;
    if (existing != null) return existing;
    final future = _doTeardown().whenComplete(() {
      _teardownFuture = null;
    });
    _teardownFuture = future;
    return future;
  }

  Future<void> _doTeardown() async {
    await _stopReadLoop();
    _cleanupHandles();
  }

  void _cleanupHandles() {
    if (_interfaceHandle != 0) {
      try {
        winUsbAbortPipe(_interfaceHandle, _inPipeId);
        winUsbFree(_interfaceHandle);
      } catch (_) {}
      _interfaceHandle = 0;
    }
    if (_deviceHandle != 0) {
      try {
        closeDevice(_deviceHandle);
      } catch (_) {}
      _deviceHandle = 0;
    }
    _inPipeId = 0;
    _outPipeId = 0;
  }
}

/// 传递给读 isolate 的上下文，只包含可跨 isolate 传递的基本类型。
class _WinUsbReadContext {
  const _WinUsbReadContext({
    required this.interfaceHandle,
    required this.inPipeId,
    required this.bufferSize,
    required this.readEvent,
    required this.shutdownEvent,
    required this.sendPort,
  });

  final int interfaceHandle;
  final int inPipeId;
  final int bufferSize;
  final int readEvent;
  final int shutdownEvent;
  final SendPort sendPort;
}

/// 读 isolate 入口：overlapped + event 异步读，等待数据或关闭信号。
void _winUsbReadLoop(_WinUsbReadContext context) {
  final events = calloc<IntPtr>(2);
  events[0] = context.readEvent;
  events[1] = context.shutdownEvent;

  final overlapped = calloc<OVERLAPPED>();
  overlapped.ref.hEvent = context.readEvent;

  final buffer = calloc<Uint8>(context.bufferSize);
  final bytesReadPtr = calloc<Uint32>();

  final sendPort = context.sendPort;

  try {
    while (true) {
      fResetEvent(context.readEvent);
      overlapped.ref.Internal = 0;
      overlapped.ref.InternalHigh = 0;
      overlapped.ref.Offset = 0;
      overlapped.ref.OffsetHigh = 0;
      bytesReadPtr.value = 0;

      final result = fWinUsbReadPipe(
        context.interfaceHandle,
        context.inPipeId,
        buffer,
        context.bufferSize,
        bytesReadPtr,
        overlapped,
      );

      if (result != 0) {
        final count = bytesReadPtr.value;
        if (count > 0) {
          sendPort.send({
            'type': 'data',
            'bytes': _copyBytes(buffer, count),
          });
        }
        continue;
      }

      final pendingError = fGetLastError();
      // 在独立 isolate 中 GetLastError() 可能不会可靠返回 ERROR_IO_PENDING，
      // 因此这里只快速识别“设备已拔出”，其余情况统一等待 overlapped 事件完成，
      // 再通过 WinUsb_GetOverlappedResult 判断最终结果。
      if (isUsbDeviceGoneError(pendingError)) {
        _sendReadError(sendPort, pendingError);
        return;
      }

      final wait = fWaitForMultipleObjects(2, events, 0, INFINITE);
      if (wait == WAIT_OBJECT_0) {
        final got = fWinUsbGetOverlappedResult(
          context.interfaceHandle,
          overlapped,
          bytesReadPtr,
          0,
        );
        if (got == 0) {
          _sendReadError(sendPort, fGetLastError());
          return;
        }
        final count = bytesReadPtr.value;
        if (count > 0) {
          sendPort.send({
            'type': 'data',
            'bytes': _copyBytes(buffer, count),
          });
        }
      } else if (wait == WAIT_OBJECT_0 + 1) {
        // 收到关闭信号。
        return;
      } else {
        sendPort.send({
          'type': 'error',
          'message': 'WaitForMultipleObjects failed: wait=$wait',
        });
        return;
      }
    }
  } finally {
    // 退出前取消可能仍挂起的 overlapped 读，避免释放内存后设备仍持有 pending I/O。
    fWinUsbAbortPipe(context.interfaceHandle, context.inPipeId);
    calloc.free(buffer);
    calloc.free(bytesReadPtr);
    calloc.free(overlapped);
    calloc.free(events);
    sendPort.send({'type': 'done'});
  }
}

Uint8List _copyBytes(Pointer<Uint8> buffer, int count) {
  final data = Uint8List(count);
  for (var i = 0; i < count; i++) {
    data[i] = buffer[i];
  }
  return data;
}

void _sendReadError(SendPort sendPort, int error) {
  if (isUsbDeviceGoneError(error)) {
    sendPort.send({'type': 'disconnected'});
  } else {
    sendPort.send({
      'type': 'error',
      'message': 'WinUsb_ReadPipe failed: error=$error',
    });
  }
}
