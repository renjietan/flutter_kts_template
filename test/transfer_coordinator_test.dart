import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/transfer_coordinator.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _AutoAckTransport implements UpdateTransport {
  _AutoAckTransport(this.devices, {this.ack = true});

  final List<(String, String)> devices;
  final bool ack;
  String? packetErrorDevice;
  final sent = <Uint8List>[];
  final _controller = StreamController<Uint8List>.broadcast(sync: true);
  bool closed = false;

  @override
  Future<void> send(Uint8List data) async {
    sent.add(data);
    if (!ack) {
      return;
    }
    final text = String.fromCharCodes(data);
    if (text.startsWith('file:')) {
      for (final (type, ip) in devices) {
        _controller.add(_fileAck(type, ip));
      }
    } else if (text.startsWith('packet:')) {
      final view = ByteData.sublistView(data);
      final crc = view.getUint32(7, Endian.big);
      final number = view.getUint32(11, Endian.big);
      final length = view.getUint32(15, Endian.big);
      for (final (type, ip) in devices) {
        final key = '$type#$ip';
        if (packetErrorDevice == key) {
          _controller.add(_packetError(type, ip, crc, number, length, 'crc'));
          packetErrorDevice = null;
        } else {
          _controller.add(_packetAck(type, ip, crc, number, length));
        }
      }
    }
  }

  @override
  Stream<Uint8List> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitValid() {
    for (final (type, ip) in devices) {
      _controller.add(_validOk(type, ip));
    }
  }

  void emitValidFor(String type, String ip) {
    _controller.add(_validOk(type, ip));
  }

  void emitValidFailFor(String type, String ip, String reason) {
    _controller.add(_validFail(type, ip, reason));
  }

  void emitUpdateOkFor(String type, String ip, String version) {
    _controller.add(_updateOk(type, ip, version));
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

Uint8List _packetError(
  String type,
  String ip,
  int crc,
  int number,
  int length,
  String reason,
) {
  final b = BytesBuilder()
    ..add('packet_fail:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip));
  final view = ByteData(12)
    ..setUint32(0, crc, Endian.big)
    ..setUint32(4, number, Endian.big)
    ..setUint32(8, length, Endian.big);
  b.add(view.buffer.asUint8List());
  b.add(reason.codeUnits);
  return b.toBytes();
}

Uint8List _validOk(String type, String ip) {
  final b = BytesBuilder()
    ..add('valid_ok:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip));
  return b.toBytes();
}

Uint8List _validFail(String type, String ip, String reason) {
  final b = BytesBuilder()
    ..add('valid_fail:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip))
    ..add(reason.codeUnits);
  return b.toBytes();
}

Uint8List _updateOk(String type, String ip, String version) {
  final b = BytesBuilder()
    ..add('update_ok:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip))
    ..add(version.codeUnits);
  return b.toBytes();
}

Future<(Directory, InstallPackageStorage)> _createStorage() async {
  final tempDir = await Directory.systemTemp.createTemp('transfer_test');
  final storage = InstallPackageStorage(
    installDirectory: Directory(p.join(tempDir.path, 'install')),
  );
  final installDir = Directory(p.join(tempDir.path, 'install'));
  await installDir.create(recursive: true);
  for (final type in ['MR9360', 'MMR200']) {
    final dir = Directory(p.join(installDir.path, 'install_xxx', type));
    await dir.create(recursive: true);
    await File(p.join(dir.path, 'cpdc_config.json')).writeAsString(
      jsonEncode({'version': '0.1.1.1'}),
    );
  }
  return (tempDir, storage);
}

Future<void> _waitForStep(
  UpdateStepController controller,
  int step,
  StepStatus status,
) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (controller.steps[step].status != status) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('step $step did not reach $status');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('updateFailReasonText', () {
    test('translates known update fail codes and falls back to raw', () {
      LocaleSettings.setLocaleSync(AppLocale.zh);
      expect(updateFailReasonText('version_mismatch'), '版本不匹配');
      expect(updateFailReasonText('install_error'), '安装失败');
      expect(updateFailReasonText('restart_error'), '重启失败');
      expect(updateFailReasonText('version_read_error'), '读取版本失败');
      expect(updateFailReasonText('unknown'), 'unknown');
    });
  });

  test('transfer acks all devices then collects valid per device', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [
      UpdateDevice(ip: '192.168.1.10', type: 'MR9360'),
      UpdateDevice(ip: '192.168.1.11', type: 'MMR200'),
    ];
    final transport = _AutoAckTransport([
      ('MR9360', '192.168.1.10'),
      ('MMR200', '192.168.1.11'),
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
      transferTimeout: const Duration(seconds: 3),
      validTimeout: const Duration(seconds: 5),
    );

    final future = coordinator.run(devices);
    await _waitForStep(controller, 4, StepStatus.running);
    transport.emitValid();
    final result = await future;

    expect(result, isTrue);
    expect(controller.steps[3].status, StepStatus.success);
    expect(controller.steps[4].status, StepStatus.success);
    expect(controller.devices[0].status, '校验通过');
    expect(controller.devices[1].status, '校验通过');
  });

  test('transfer times out and terminates when no ack', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [UpdateDevice(ip: '192.168.1.10', type: 'MR9360')];
    final transport = _AutoAckTransport([('MR9360', '192.168.1.10')], ack: false);
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
      transferTimeout: const Duration(milliseconds: 20),
      validTimeout: const Duration(milliseconds: 20),
    );

    final result = await coordinator.run(devices);

    expect(result, isFalse);
    expect(controller.phase, UpdatePhase.finished);
    expect(controller.summary, '传输前置指令超时');
    expect(controller.steps[3].status, StepStatus.failed);
    expect(transport.closed, isTrue);
  });

  test('valid replies after the 5s window are discarded', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [
      UpdateDevice(ip: '192.168.1.10', type: 'MR9360'),
      UpdateDevice(ip: '192.168.1.11', type: 'MMR200'),
    ];
    final transport = _AutoAckTransport([
      ('MR9360', '192.168.1.10'),
      ('MMR200', '192.168.1.11'),
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
      transferTimeout: const Duration(seconds: 3),
      validTimeout: const Duration(milliseconds: 100),
    );

    final future = coordinator.run(devices);
    await _waitForStep(controller, 4, StepStatus.running);
    // 第一台在窗口内回 valid，第二台不立即回。
    transport.emitValidFor('MR9360', '192.168.1.10');
    // 窗口结束后，第二台才回 valid（应被丢弃）。
    await Future<void>.delayed(const Duration(milliseconds: 200));
    transport.emitValidFor('MMR200', '192.168.1.11');
    await future;

    expect(controller.devices[0].status, '校验通过');
    expect(controller.devices[1].status, '校验超时');
  });

  test('receipt waits only for valid-passed devices', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [
      UpdateDevice(ip: '192.168.1.10', type: 'MR9360'),
      UpdateDevice(ip: '192.168.1.11', type: 'MMR200'),
    ];
    final transport = _AutoAckTransport([
      ('MR9360', '192.168.1.10'),
      ('MMR200', '192.168.1.11'),
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
      transferTimeout: const Duration(seconds: 3),
      validTimeout: const Duration(seconds: 5),
      receiptTimeout: const Duration(seconds: 30),
    );

    // 传输 + valid：MR9360 校验通过，MMR200 校验失败。
    final runFuture = coordinator.run(devices);
    await _waitForStep(controller, 4, StepStatus.running);
    transport.emitValidFor('MR9360', '192.168.1.10');
    transport.emitValidFailFor('MMR200', '192.168.1.11', 'crc');
    await runFuture;

    expect(controller.devices[0].status, '校验通过');
    expect(controller.devices[1].status, '校验失败: crc');

    // 回执：只等 MR9360。
    final receiptFuture = coordinator.runReceipt(devices);
    await _waitForStep(controller, 6, StepStatus.running);
    transport.emitUpdateOkFor('MR9360', '192.168.1.10', '0.1.1.1');
    await receiptFuture;

    expect(controller.devices[0].status, '更新成功');
    expect(controller.devices[0].result, '成功(0.1.1.1)');
    expect(controller.devices[1].status, '校验失败: crc');
    expect(controller.phase, UpdatePhase.finished);
    expect(controller.summary, contains('跳过 1'));
  });

  test('packetError triggers packet resend', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [
      UpdateDevice(ip: '192.168.1.10', type: 'MR9360'),
      UpdateDevice(ip: '192.168.1.11', type: 'MMR200'),
    ];
    final transport = _AutoAckTransport([
      ('MR9360', '192.168.1.10'),
      ('MMR200', '192.168.1.11'),
    ]);
    transport.packetErrorDevice = 'MMR200#192.168.1.11';
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
      transferTimeout: const Duration(seconds: 3),
      validTimeout: const Duration(seconds: 5),
    );

    final future = coordinator.run(devices);
    await _waitForStep(controller, 4, StepStatus.running);
    transport.emitValid();
    final result = await future;

    expect(result, isTrue);
    expect(controller.steps[3].status, StepStatus.success);
    // 1 个 file: + 首次 packet: + 重发 packet: 共 3 次发送。
    expect(transport.sent.length, 3);
  });
}
