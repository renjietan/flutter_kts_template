import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/transfer_coordinator.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 可控 ACK 的传输 mock：发送只记录，ACK 由测试手动触发。
class _ManualTransport implements UpdateTransport {
  _ManualTransport(this.devices);

  final List<(String, String)> devices;
  final List<Uint8List> sent = [];
  final _controller = StreamController<UpdateDatagram>.broadcast(sync: true);
  bool closed = false;

  @override
  Future<void> send(Uint8List data) async {
    sent.add(data);
  }

  @override
  Stream<UpdateDatagram> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitFileAcks() {
    for (final (type, ip) in devices) {
      _controller.add(UpdateDatagram(data: _fileAck(type, ip), sourceIp: ip));
    }
  }

  /// 从已发送的 packet 里找指定包号，对所有设备回 `packet_ok`。
  void emitPacketOk(int number) {
    for (final data in sent) {
      final text = String.fromCharCodes(data);
      if (!text.startsWith('packet:')) {
        continue;
      }
      final view = ByteData.sublistView(data);
      final crc = view.getUint32(7, Endian.big);
      final n = view.getUint32(11, Endian.big);
      final length = view.getUint32(15, Endian.big);
      if (n != number) {
        continue;
      }
      for (final (type, ip) in devices) {
        _controller.add(
          UpdateDatagram(
            data: _packetAck(type, ip, crc, n, length),
            sourceIp: ip,
          ),
        );
      }
      return;
    }
  }

  void emitValidOk() {
    for (final (type, ip) in devices) {
      _controller.add(UpdateDatagram(data: _validOk(type, ip), sourceIp: ip));
    }
  }

  int packetCount() =>
      sent.where((d) => String.fromCharCodes(d).startsWith('packet:')).length;

  /// 最后发送的 packet 的包号（1-based）。
  int lastPacketNumber() {
    for (final data in sent.reversed) {
      final text = String.fromCharCodes(data);
      if (!text.startsWith('packet:')) {
        continue;
      }
      return ByteData.sublistView(data).getUint32(11, Endian.big);
    }
    return 0;
  }
}

Uint8List _fileAck(String type, String ip) {
  final b = BytesBuilder()
    ..add('fileAck:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip));
  final view = ByteData(12)
    ..setUint32(0, 0x0a0b0c0d, Endian.big)
    ..setUint32(4, 1, Endian.big)
    ..setUint32(8, 5, Endian.big);
  b.add(view.buffer.asUint8List());
  b.add('a.zip'.codeUnits);
  return b.toBytes();
}

Uint8List _packetAck(String type, String ip, int crc, int number, int length) {
  final b = BytesBuilder()
    ..add('packet_ok:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip));
  final view = ByteData(12)
    ..setUint32(0, crc, Endian.big)
    ..setUint32(4, number, Endian.big)
    ..setUint32(8, length, Endian.big);
  b.add(view.buffer.asUint8List());
  return b.toBytes();
}

Uint8List _validOk(String type, String ip) {
  final b = BytesBuilder()
    ..add('valid_ok:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip));
  return b.toBytes();
}

Future<(Directory, InstallPackageStorage)> _createStorage() async {
  final tempDir = await Directory.systemTemp.createTemp('transfer_pause_test');
  final installDir = Directory(p.join(tempDir.path, 'install'));
  final typeDir = Directory(p.join(installDir.path, 'install_xxx', 'MR9360'));
  await typeDir.create(recursive: true);
  await File(
    p.join(typeDir.path, 'cpdc_config.json'),
  ).writeAsString(jsonEncode({'version': '0.1.1.1'}));
  // 高熵 payload，确保 ZIP 拆成多个分包。
  final rnd = Random(7);
  await File(
    p.join(typeDir.path, 'payload.bin'),
  ).writeAsBytes(List<int>.generate(700, (_) => rnd.nextInt(256)));
  return (tempDir, InstallPackageStorage(installDirectory: installDir));
}

Future<void> _waitFor(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('condition not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// 循环 ACK 所有已发送的 packet，直到进入校验阶段。
Future<void> _ackAllPackets(
  _ManualTransport transport,
  UpdateStepController controller,
) async {
  var lastSeen = 0;
  while (controller.activeStep != 4) {
    await _waitFor(() {
      return transport.packetCount() > lastSeen || controller.activeStep == 4;
    });
    if (controller.activeStep == 4) {
      break;
    }
    transport.emitPacketOk(transport.lastPacketNumber());
    lastSeen = transport.packetCount();
  }
}

void main() {
  test('pause interrupts immediately and resume resends from cursor', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [UpdateDevice(ip: '10.0.0.1', type: 'MR9360')];
    final transport = _ManualTransport([('MR9360', '10.0.0.1')]);
    final session = UpdateSession(transport: transport);
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    controller.devices.addAll(devices);
    final coordinator = TransferCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      transferTimeout: const Duration(seconds: 10),
      validTimeout: const Duration(milliseconds: 200),
    );

    final future = coordinator.run(devices);

    await _waitFor(() => transport.sent.isNotEmpty);
    transport.emitFileAcks();
    await _waitFor(() => transport.packetCount() >= 1);

    coordinator.pause();
    expect(coordinator.state, TransferState.paused);
    expect(controller.transferStage, TransferStage.paused);

    final countAfterPause = transport.packetCount();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(transport.packetCount(), countAfterPause);

    coordinator.resume();
    expect(controller.transferStage, TransferStage.sending);

    await _waitFor(() => transport.packetCount() > countAfterPause);
    await _ackAllPackets(transport, controller);
    transport.emitValidOk();

    final result = await future;
    expect(result, isTrue);
    expect(controller.steps[3].status, StepStatus.success);
  });

  test('cancel interrupts transfer and resets state', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [UpdateDevice(ip: '10.0.0.1', type: 'MR9360')];
    final transport = _ManualTransport([('MR9360', '10.0.0.1')]);
    final session = UpdateSession(transport: transport);
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    controller.devices.addAll(devices);
    final coordinator = TransferCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      transferTimeout: const Duration(seconds: 10),
    );

    final future = coordinator.run(devices);

    await _waitFor(() => transport.sent.isNotEmpty);
    transport.emitFileAcks();
    await _waitFor(() => transport.packetCount() >= 1);

    coordinator.cancel();
    expect(coordinator.state, TransferState.cancelled);
    expect(controller.transferStage, TransferStage.finished);

    final result = await future;
    expect(result, isFalse);
  });

  test('multi-device pause then resume aligns all devices', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [
      UpdateDevice(ip: '10.0.0.1', type: 'MR9360'),
      UpdateDevice(ip: '10.0.0.2', type: 'MR9360'),
    ];
    final transport = _ManualTransport([
      ('MR9360', '10.0.0.1'),
      ('MR9360', '10.0.0.2'),
    ]);
    final session = UpdateSession(transport: transport);
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    controller.devices.addAll(devices);
    final coordinator = TransferCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      transferTimeout: const Duration(seconds: 10),
      validTimeout: const Duration(milliseconds: 200),
    );

    final future = coordinator.run(devices);

    await _waitFor(() => transport.sent.isNotEmpty);
    transport.emitFileAcks();
    await _waitFor(() => transport.packetCount() >= 1);

    coordinator.pause();
    expect(coordinator.state, TransferState.paused);

    coordinator.resume();
    expect(controller.transferStage, TransferStage.sending);

    await _waitFor(() => transport.packetCount() >= 2);
    await _ackAllPackets(transport, controller);
    transport.emitValidOk();

    final result = await future;
    expect(result, isTrue);
    expect(controller.steps[3].status, StepStatus.success);
    expect(controller.devices[0].status, '校验通过');
    expect(controller.devices[1].status, '校验通过');
  });

}
