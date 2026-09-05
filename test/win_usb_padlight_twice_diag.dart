import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_ffi.dart';

void main() {
  const vid = 0x1D6B;
  const pid = 0x0104;

  final path = findWinUsbDevicePathByDeviceClasses(
    vid: vid,
    pid: pid,
    interfaceNumber: 2,
    interfaceGuid: 'fed3a0be-9515-4920-812b-51d602e63752',
  );
  if (path == null) {
    print('NOT_FOUND');
    return;
  }

  final deviceHandle = openDevice(path);
  final interfaceHandle = winUsbInitialize(deviceHandle);

  var inPipe = 0;
  var outPipe = 0;
  for (var iface = 0; iface < 8; iface++) {
    for (final p in listPipes(interfaceHandle, iface)) {
      if (p.pipeType == PIPE_TYPE_BULK) {
        if (isInPipe(p.pipeId)) {
          inPipe = p.pipeId;
        } else {
          outPipe = p.pipeId;
        }
      }
    }
    if (inPipe != 0 && outPipe != 0) break;
  }

  setPipeTimeout(interfaceHandle, outPipe, 3000);
  setPipeTimeout(interfaceHandle, inPipe, 3000);

  final cmd = Uint8List.fromList(utf8.encode('PAD_LIGHT\n'));
  print('WRITE=${winUsbWritePipe(interfaceHandle, outPipe, cmd)}');

  for (var i = 1; i <= 3; i++) {
    try {
      final data = winUsbReadPipe(interfaceHandle, inPipe, 512);
      print(
        'READ$i len=${data.length} '
        'hex=${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} '
        'text=${utf8.decode(data, allowMalformed: true)}',
      );
    } catch (e) {
      print('READ$i ERROR=$e');
      break;
    }
  }

  winUsbFree(interfaceHandle);
  closeDevice(deviceHandle);
  print('DONE');
}
