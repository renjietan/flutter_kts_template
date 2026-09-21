import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_flow_coordinator.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _MockTransport implements UpdateTransport {
  final _controller = StreamController<Uint8List>.broadcast();
  bool closed = false;

  @override
  Future<void> send(Uint8List data) async {}

  @override
  Stream<Uint8List> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitBytes(Uint8List bytes) => _controller.add(bytes);
}

Uint8List _authAck(String deviceType, String ip) {
  final builder = BytesBuilder()
    ..add('authAck:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: deviceType, ip: ip));
  return builder.toBytes();
}

Uint8List _versionOk(String deviceType, String ip, String version) {
  final builder = BytesBuilder()
    ..add('version_ok:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: deviceType, ip: ip))
    ..add(version.codeUnits);
  return builder.toBytes();
}

Future<(Directory, InstallPackageStorage)> _createStorage() async {
  final tempDir = await Directory.systemTemp.createTemp('update_flow_test');
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
  test('auth inserts devices (ip duplicate) and version fills versions', () async {
    final transport = _MockTransport();
    final session = UpdateSession(transport: transport);
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final coordinator = UpdateFlowCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      targetVersion: '0.1.1.1',
      authTimeout: const Duration(milliseconds: 100),
      versionTimeout: const Duration(milliseconds: 100),
    );

    final future = coordinator.runAuthAndVersion();

    await Future<void>.delayed(const Duration(milliseconds: 20));
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));
    transport.emitBytes(_authAck('MMR200', '192.168.1.11'));

    await _waitForStep(controller, 2, StepStatus.running);
    transport.emitBytes(_versionOk('MR9360', '192.168.1.10', '0.0.0.1'));
    transport.emitBytes(_versionOk('MMR200', '192.168.1.11', '0.0.0.2'));

    await future;

    expect(controller.devices.length, 3);
    expect(controller.devices[0].ip, '192.168.1.10');
    expect(controller.devices[1].ip, '192.168.1.10（重复）');
    expect(controller.devices[2].ip, '192.168.1.11');
    expect(controller.devices[0].currentVersion, '0.0.0.1');
    expect(controller.devices[2].currentVersion, '0.0.0.2');
    expect(controller.devices[0].newVersion, '0.1.1.1');
    expect(controller.devices[2].newVersion, '0.1.1.1');
    expect(controller.devices[0].status, '需更新');
    expect(controller.devices[2].status, '需更新');
    expect(controller.phase, UpdatePhase.paused);
    expect(controller.steps[1].status, StepStatus.success);
    expect(controller.steps[2].status, StepStatus.success);
  });

  test('auth skips unsupported device types', () async {
    final transport = _MockTransport();
    final session = UpdateSession(transport: transport);
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final coordinator = UpdateFlowCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      targetVersion: '0.1.1.1',
      authTimeout: const Duration(milliseconds: 100),
      versionTimeout: const Duration(milliseconds: 100),
    );

    final future = coordinator.runAuthAndVersion();

    await Future<void>.delayed(const Duration(milliseconds: 20));
    transport.emitBytes(_authAck('Server', '192.168.1.20'));
    transport.emitBytes(_authAck('IEC', '192.168.1.21'));
    transport.emitBytes(_authAck('SmallHandheld', '192.168.1.22'));
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));

    await _waitForStep(controller, 2, StepStatus.running);
    transport.emitBytes(_versionOk('MR9360', '192.168.1.10', '0.0.0.1'));

    await future;

    expect(controller.devices.length, 1);
    expect(controller.devices.single.type, 'MR9360');
    expect(controller.devices.single.ip, '192.168.1.10');
  });

  test('auth timeout terminates and resets session', () async {
    final transport = _MockTransport();
    final session = UpdateSession(transport: transport);
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    final (tempDir, storage) = await _createStorage();
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final coordinator = UpdateFlowCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      targetVersion: '0.1.1.1',
      authTimeout: const Duration(milliseconds: 20),
      versionTimeout: const Duration(milliseconds: 20),
    );

    await coordinator.runAuthAndVersion();

    expect(controller.phase, UpdatePhase.finished);
    expect(controller.summary, '认证超时');
    expect(controller.steps[1].status, StepStatus.failed);
    expect(transport.closed, isTrue);
  });
}
