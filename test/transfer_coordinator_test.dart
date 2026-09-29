import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/transfer_coordinator.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/fail_reason_text.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _AutoAckTransport implements UpdateTransport {
  _AutoAckTransport(this.devices, {this.ack = true});

  final List<(String, String)> devices;
  final bool ack;
  String? packetErrorDevice;
  final sent = <Uint8List>[];
  final _controller = StreamController<UpdateDatagram>.broadcast(sync: true);
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
        _controller.add(UpdateDatagram(data: _fileAck(type, ip), sourceIp: ip));
      }
    } else if (text.startsWith('packet:')) {
      final view = ByteData.sublistView(data);
      final crc = view.getUint32(7, Endian.big);
      final number = view.getUint32(11, Endian.big);
      final length = view.getUint32(15, Endian.big);
      for (final (type, ip) in devices) {
        final key = '$type#$ip';
        if (packetErrorDevice == key) {
          _controller.add(
            UpdateDatagram(
              data: _packetError(type, ip, crc, number, length, 'crc'),
              sourceIp: ip,
            ),
          );
          packetErrorDevice = null;
        } else {
          _controller.add(
            UpdateDatagram(
              data: _packetAck(type, ip, crc, number, length),
              sourceIp: ip,
            ),
          );
        }
      }
    } else if (text.startsWith('write:')) {
      for (final (type, ip) in devices) {
        _controller.add(UpdateDatagram(data: _writeOk(type, ip), sourceIp: ip));
      }
    }
  }

  @override
  Stream<UpdateDatagram> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitValid() {
    for (final (type, ip) in devices) {
      _controller.add(UpdateDatagram(data: _validOk(type, ip), sourceIp: ip));
    }
  }

  void emitValidFor(String type, String ip) {
    _controller.add(UpdateDatagram(data: _validOk(type, ip), sourceIp: ip));
  }

  void emitValidFailFor(String type, String ip, String reason) {
    _controller.add(
      UpdateDatagram(data: _validFail(type, ip, reason), sourceIp: ip),
    );
  }

  void emitWriteOkFor(String type, String ip) {
    _controller.add(UpdateDatagram(data: _writeOk(type, ip), sourceIp: ip));
  }

  void emitUpdateOkFor(String type, String ip, String version) {
    _controller.add(
      UpdateDatagram(data: _updateOk(type, ip, version), sourceIp: ip),
    );
  }

  void emitUpdateFailFor(String type, String ip, String reason) {
    _controller.add(
      UpdateDatagram(data: _updateFail(type, ip, reason), sourceIp: ip),
    );
  }

  void emitWriteFailFor(String type, String ip, String reason) {
    _controller.add(
      UpdateDatagram(data: _writeFail(type, ip, reason), sourceIp: ip),
    );
  }
}

/// 模拟 CPDC 的 `sequence` 兜底：首次收到「超前包」时回 `sequence:missingNumber`，
/// 补发该包后恢复正常 ACK，用于验证 CPDS 会补发缺失分包。
class _SequenceTransport implements UpdateTransport {
  _SequenceTransport(this.type, this.ip, this.missingNumber);

  final String type;
  final String ip;
  final int missingNumber;
  bool _claimed = false;
  final sent = <Uint8List>[];
  final _controller = StreamController<UpdateDatagram>.broadcast(sync: true);
  bool closed = false;

  @override
  Future<void> send(Uint8List data) async {
    sent.add(data);
    final text = String.fromCharCodes(data);
    if (text.startsWith('file:')) {
      _controller.add(UpdateDatagram(data: _fileAck(type, ip), sourceIp: ip));
      return;
    }
    if (!text.startsWith('packet:')) {
      return;
    }
    final view = ByteData.sublistView(data);
    final crc = view.getUint32(7, Endian.big);
    final number = view.getUint32(11, Endian.big);
    final length = view.getUint32(15, Endian.big);
    if (!_claimed && number > missingNumber) {
      _claimed = true;
      _controller.add(
        UpdateDatagram(
          data: _packetError(
            type,
            ip,
            crc,
            number,
            length,
            'sequence:$missingNumber',
          ),
          sourceIp: ip,
        ),
      );
    } else {
      _controller.add(
        UpdateDatagram(
          data: _packetAck(type, ip, crc, number, length),
          sourceIp: ip,
        ),
      );
    }
  }

  @override
  Stream<UpdateDatagram> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitValid() {
    _controller.add(UpdateDatagram(data: _validOk(type, ip), sourceIp: ip));
  }
}

/// 多设备模拟：在某个超前包上，不同设备回不同 `sequence`，用于验证
/// CPDS 回退到「最小的缺失包号」。
class _MultiSequenceTransport implements UpdateTransport {
  _MultiSequenceTransport(this.devices);

  final List<(String, String)> devices;
  bool _claimed = false;
  final sent = <Uint8List>[];
  final _controller = StreamController<UpdateDatagram>.broadcast(sync: true);
  bool closed = false;

  @override
  Future<void> send(Uint8List data) async {
    sent.add(data);
    final text = String.fromCharCodes(data);
    if (text.startsWith('file:')) {
      for (final (type, ip) in devices) {
        _controller.add(UpdateDatagram(data: _fileAck(type, ip), sourceIp: ip));
      }
      return;
    }
    if (!text.startsWith('packet:')) {
      return;
    }
    final view = ByteData.sublistView(data);
    final crc = view.getUint32(7, Endian.big);
    final number = view.getUint32(11, Endian.big);
    final length = view.getUint32(15, Endian.big);
    if (!_claimed && number >= 6) {
      _claimed = true;
      final (aType, aIp) = devices[0];
      final (bType, bIp) = devices[1];
      _controller.add(
        UpdateDatagram(
          data: _packetError(aType, aIp, crc, number, length, 'sequence:5'),
          sourceIp: aIp,
        ),
      );
      _controller.add(
        UpdateDatagram(
          data: _packetError(bType, bIp, crc, number, length, 'sequence:3'),
          sourceIp: bIp,
        ),
      );
    } else {
      for (final (type, ip) in devices) {
        _controller.add(
          UpdateDatagram(
            data: _packetAck(type, ip, crc, number, length),
            sourceIp: ip,
          ),
        );
      }
    }
  }

  @override
  Stream<UpdateDatagram> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitValid() {
    for (final (type, ip) in devices) {
      _controller.add(UpdateDatagram(data: _validOk(type, ip), sourceIp: ip));
    }
  }
}

/// 手动控制 ACK 的传输：用于验证「错误/sequence 不提前结束窗口」的时序。
class _ManualPacketTransport implements UpdateTransport {
  final sent = <Uint8List>[];
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

  void emitFileAck(String type, String ip) {
    _controller.add(UpdateDatagram(data: _fileAck(type, ip), sourceIp: ip));
  }

  void emitPacketOk(String type, String ip, int crc, int number, int length) {
    _controller.add(
      UpdateDatagram(
        data: _packetAck(type, ip, crc, number, length),
        sourceIp: ip,
      ),
    );
  }

  void emitPacketFail(
    String type,
    String ip,
    int crc,
    int number,
    int length,
    String reason,
  ) {
    _controller.add(
      UpdateDatagram(
        data: _packetError(type, ip, crc, number, length, reason),
        sourceIp: ip,
      ),
    );
  }

  void emitValid(String type, String ip) {
    _controller.add(UpdateDatagram(data: _validOk(type, ip), sourceIp: ip));
  }

  int packetCount() =>
      sent.where((d) => String.fromCharCodes(d).startsWith('packet:')).length;
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

Uint8List _writeOk(String type, String ip) {
  final b = BytesBuilder()
    ..add('write_ok:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip));
  return b.toBytes();
}

Uint8List _updateOk(String type, String ip, String version) {
  final b = BytesBuilder()
    ..add('update_ok:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip))
    ..add(version.codeUnits);
  return b.toBytes();
}

Uint8List _updateFail(String type, String ip, String reason) {
  final b = BytesBuilder()
    ..add('update_fail:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip))
    ..add(reason.codeUnits);
  return b.toBytes();
}

Uint8List _writeFail(String type, String ip, String reason) {
  final b = BytesBuilder()
    ..add('write_fail:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: type, ip: ip))
    ..add(reason.codeUnits);
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
    await File(
      p.join(dir.path, 'cpdc_config.json'),
    ).writeAsString(jsonEncode({'version': '0.1.1.1'}));
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

Future<void> _waitFor(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('condition not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('selfUpdateFailReasonText', () {
    test('translates known fail codes and falls back to raw', () {
      LocaleSettings.setLocaleSync(AppLocale.zh);
      expect(selfUpdateFailReasonText('format'), '版本号格式非法');
      expect(selfUpdateFailReasonText('length'), '分包长度错误');
      expect(selfUpdateFailReasonText('crc'), '校验失败（CRC）');
      expect(selfUpdateFailReasonText('sequence:4'), '分包顺序错误，缺少第 4 包');
      expect(selfUpdateFailReasonText('size'), '文件大小不符');
      expect(selfUpdateFailReasonText('zip'), '解压失败');
      expect(selfUpdateFailReasonText('no_header'), '未收到文件头');
      expect(selfUpdateFailReasonText('missing_packet:2,3'), '缺少分包 2,3');
      expect(selfUpdateFailReasonText('mismatch'), '文件头不匹配');
      expect(selfUpdateFailReasonText('install_error'), '安装/写盘失败');
      expect(selfUpdateFailReasonText('restart_error'), '重启失败');
      expect(selfUpdateFailReasonText('restart_spawn_fail'), '启动脚本失败');
      expect(selfUpdateFailReasonText('finalize_fail'), '替换可执行文件失败');
      expect(selfUpdateFailReasonText('write_params_fail'), '写重启参数失败');
      expect(selfUpdateFailReasonText('version_read_error'), '读取版本失败');
      expect(selfUpdateFailReasonText('version_mismatch'), '版本不匹配');
      expect(selfUpdateFailReasonText('unknown'), 'unknown');
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
    final transport = _AutoAckTransport([
      ('MR9360', '192.168.1.10'),
    ], ack: false);
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
    // 1 个 file: + 首次 packet: + 重发 packet: 共 3 次传输发送（valid: 不计入）。
    final transferSends = transport.sent.where((d) {
      final text = String.fromCharCodes(d);
      return text.startsWith('file:') || text.startsWith('packet:');
    }).length;
    expect(transferSends, 3);
  });

  test('PacketFailReply parses sequence missing packet number', () {
    final bytes = _packetError(
      'MR9360',
      '192.168.1.10',
      0x0a0b0c0d,
      2,
      10,
      'sequence:1',
    );
    final reply = UpdateProtocol.parseReply(bytes);
    expect(reply, isA<PacketFailReply>());
    final fail = reply as PacketFailReply;
    expect(fail.reason, 'sequence:1');
    expect(fail.missingPacketNumber, 1);
  });

  test(
    'sequence fail rewinds cursor and resends from missing packet',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'transfer_seq_test',
      );
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final installDir = Directory(p.join(tempDir.path, 'install'));
      final typeDir = Directory(
        p.join(installDir.path, 'install_xxx', 'MR9360'),
      );
      await typeDir.create(recursive: true);
      await File(
        p.join(typeDir.path, 'cpdc_config.json'),
      ).writeAsString(jsonEncode({'version': '0.1.1.1'}));
      // 写入高熵文件，确保 ZIP 拆成多个分包（每包 ≤1381 字节）。
      final rnd = Random(42);
      await File(
        p.join(typeDir.path, 'payload.bin'),
      ).writeAsBytes(List<int>.generate(3000, (_) => rnd.nextInt(256)));
      final storage = InstallPackageStorage(installDirectory: installDir);

      final devices = [UpdateDevice(ip: '192.168.1.10', type: 'MR9360')];
      final transport = _SequenceTransport('MR9360', '192.168.1.10', 2);
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
        transferTimeout: const Duration(milliseconds: 200),
        validTimeout: const Duration(milliseconds: 200),
      );

      final future = coordinator.run(devices);
      await _waitForStep(controller, 4, StepStatus.running);
      transport.emitValid();
      final result = await future;

      expect(result, isTrue);
      int countPacket(int n) => transport.sent.where((d) {
        final text = String.fromCharCodes(d);
        if (!text.startsWith('packet:')) {
          return false;
        }
        return ByteData.sublistView(d).getUint32(11, Endian.big) == n;
      }).length;
      // 游标回退到 S=2：包 1 只发一次，包 2、包 3 因回退重发各出现 2 次。
      expect(countPacket(1), 1);
      expect(countPacket(2), 2);
      expect(countPacket(3), 2);
    },
  );

  test('multiple sequences rewind to the minimum missing packet number',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'transfer_multi_seq_test',
    );
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final installDir = Directory(p.join(tempDir.path, 'install'));
    for (final type in ['MR9360', 'MMR200']) {
      final dir = Directory(p.join(installDir.path, 'install_xxx', type));
      await dir.create(recursive: true);
      await File(
        p.join(dir.path, 'cpdc_config.json'),
      ).writeAsString(jsonEncode({'version': '0.1.1.1'}));
    }
    final rnd = Random(42);
    await File(
      p.join(installDir.path, 'install_xxx', 'MR9360', 'payload.bin'),
    ).writeAsBytes(List<int>.generate(10000, (_) => rnd.nextInt(256)));
    final storage = InstallPackageStorage(installDirectory: installDir);

    final devices = [
      UpdateDevice(ip: '192.168.1.10', type: 'MR9360'),
      UpdateDevice(ip: '192.168.1.11', type: 'MMR200'),
    ];
    final transport = _MultiSequenceTransport([
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
      transferTimeout: const Duration(milliseconds: 200),
      validTimeout: const Duration(milliseconds: 200),
    );

    final future = coordinator.run(devices);
    await _waitForStep(controller, 4, StepStatus.running);
    transport.emitValid();
    final result = await future;

    expect(result, isTrue);
    int countPacket(int n) => transport.sent.where((d) {
          final text = String.fromCharCodes(d);
          if (!text.startsWith('packet:')) {
            return false;
          }
          return ByteData.sublistView(d).getUint32(11, Endian.big) == n;
        }).length;
    // 回退到最小 S=3：包 3/4 重发各 2 次，包 2 只发 1 次。
    expect(countPacket(3), 2);
    expect(countPacket(4), 2);
    expect(countPacket(2), 1);
  });

  test('packet length/crc error does not early-exit and retries after window',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'transfer_crc_window_test',
    );
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final installDir = Directory(p.join(tempDir.path, 'install'));
    final typeDir = Directory(p.join(installDir.path, 'install_xxx', 'MR9360'));
    await typeDir.create(recursive: true);
    await File(
      p.join(typeDir.path, 'cpdc_config.json'),
    ).writeAsString(jsonEncode({'version': '0.1.1.1'}));
    final storage = InstallPackageStorage(installDirectory: installDir);

    final devices = [UpdateDevice(ip: '192.168.1.10', type: 'MR9360')];
    final transport = _ManualPacketTransport();
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
      transferTimeout: const Duration(milliseconds: 150),
      validTimeout: const Duration(milliseconds: 200),
    );

    final future = coordinator.run(devices);

    // 等 file 指令发出并回 fileAck。
    await _waitFor(() => transport.sent.isNotEmpty);
    transport.emitFileAck('MR9360', '192.168.1.10');
    await _waitFor(() => transport.packetCount() >= 1);

    final view = ByteData.sublistView(transport.sent.last);
    final crc = view.getUint32(7, Endian.big);
    final number = view.getUint32(11, Endian.big);
    final length = view.getUint32(15, Endian.big);
    transport.emitPacketFail(
      'MR9360',
      '192.168.1.10',
      crc,
      number,
      length,
      'crc',
    );

    final countBefore = transport.packetCount();
    // 窗口不应提前结束：等待小于 timeout 后不应发新包。
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(transport.packetCount(), countBefore);

    // 窗口满 150ms 后应重发同一包。
    await _waitFor(() => transport.packetCount() > countBefore);
    expect(transport.packetCount(), countBefore + 1);

    // 收尾：回 packet_ok 让流程进入 valid 并结束。
    transport.emitPacketOk('MR9360', '192.168.1.10', crc, number, length);
    await _waitForStep(controller, 4, StepStatus.running);
    transport.emitValid('MR9360', '192.168.1.10');
    final result = await future;
    expect(result, isTrue);
  });

  test('valid timeout enters recoverable failure state', () async {
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final devices = [UpdateDevice(ip: '192.168.1.10', type: 'MR9360')];
    final transport = _AutoAckTransport([('MR9360', '192.168.1.10')]);
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
      validTimeout: const Duration(milliseconds: 20),
    );

    // 传输成功，但 valid 3 窗口内没有任何设备回 valid_ok/valid_fail。
    final result = await coordinator.run(devices);

    expect(result, isFalse);
    expect(controller.steps[4].status, StepStatus.failed);
    expect(controller.phase, UpdatePhase.validFailed);
    expect(controller.devices.single.status, '校验超时');
    expect(controller.summary, '校验失败：0 台失败，1 台超时');
  });

  test('runUpdate collects receipts and marks device results', () async {
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
      writeTimeout: const Duration(seconds: 5),
      receiptTimeout: const Duration(seconds: 5),
    );

    final runFuture = coordinator.run(devices);
    await _waitForStep(controller, 4, StepStatus.running);
    transport.emitValid();
    expect(await runFuture, isTrue);

    final writeFuture = coordinator.runWrite();
    await _waitForStep(controller, 5, StepStatus.running);
    transport.emitWriteOkFor('MR9360', '192.168.1.10');
    transport.emitWriteOkFor('MMR200', '192.168.1.11');
    expect(await writeFuture, isTrue);

    final updateFuture = coordinator.runUpdate();
    await _waitFor(() => controller.activeStep == 6);
    transport.emitUpdateOkFor('MR9360', '192.168.1.10', '0.1.1.1');
    transport.emitUpdateFailFor('MMR200', '192.168.1.11', 'mismatch');
    await updateFuture;

    expect(controller.steps[5].status, StepStatus.success);
    expect(controller.steps[6].status, StepStatus.success);
    expect(controller.phase, UpdatePhase.finished);
    expect(controller.devices[0].status, '更新成功');
    expect(controller.devices[0].result, 'v0.1.1.1');
    expect(controller.devices[1].status, '更新失败');
    expect(
      controller.summary,
      '更新完成：成功 1 台，失败 1 台，超时 0 台',
    );
  });

}
