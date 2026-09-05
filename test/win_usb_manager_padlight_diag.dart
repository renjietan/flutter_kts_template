import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/win-usb/win_usb_bulk_manager.dart';

void main() async {
  final manager = WinUsbBulkManager.instance;
  final connected = await manager.connect();
  print('CONNECTED=$connected');
  if (!connected) return;

  final received = <Uint8List>[];
  final sub = manager.listenData().listen(received.add);

  final written = await manager.write(
    Uint8List.fromList(utf8.encode('PAD_LIGHT\n')),
  );
  print('WRITTEN=$written');

  await Future<void>.delayed(const Duration(seconds: 3));
  await sub.cancel();

  print('RECEIVED_COUNT=${received.length}');
  for (final chunk in received) {
    print(
      'CHUNK len=${chunk.length} '
      'hex=${chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} '
      'text=${utf8.decode(chunk, allowMalformed: true)}',
    );
  }

  await manager.disconnect();
  print('DONE');
}
