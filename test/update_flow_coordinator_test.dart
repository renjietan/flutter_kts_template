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
  final _controller = StreamController<UpdateDatagram>.broadcast();
  bool closed = false;

  @override
  Future<void> send(Uint8List data) async {}

  @override
  Stream<UpdateDatagram> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitBytes(Uint8List bytes) =>
      _controller.add(UpdateDatagram(data: bytes, sourceIp: '192.168.1.10'));
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

Uint8List _versionFail(String deviceType, String ip, String reason) {
  final builder = BytesBuilder()
    ..add('version_fail:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: deviceType, ip: ip))
    ..add(reason.codeUnits);
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

void main() {
  test('auth deduplicates duplicate replies and fills versions', () async {
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

    final future = coordinator.runAuthAndVersion(2);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));
    // 同一设备（类型+IP）重复回复，应被去重。
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));
    transport.emitBytes(_authAck('MMR200', '192.168.1.11'));

    await _waitForStep(controller, 2, StepStatus.running);
    transport.emitBytes(_versionOk('MR9360', '192.168.1.10', '0.0.0.1'));
    transport.emitBytes(_versionOk('MMR200', '192.168.1.11', '0.0.0.2'));

    await future;

    expect(controller.devices.length, 2);
    expect(controller.devices[0].ip, '192.168.1.10');
    expect(controller.devices[1].ip, '192.168.1.11');
    expect(controller.devices[0].currentVersion, '0.0.0.1');
    expect(controller.devices[1].currentVersion, '0.0.0.2');
    expect(controller.devices[0].newVersion, '0.1.1.1');
    expect(controller.devices[1].newVersion, '0.1.1.1');
    expect(controller.devices[0].status, '需更新');
    expect(controller.devices[1].status, '需更新');
    expect(controller.activeStep, 3);
    expect(controller.transferStage, TransferStage.notStarted);
    expect(controller.steps[1].status, StepStatus.success);
    expect(controller.steps[2].status, StepStatus.success);
  });

  test('auth marks duplicated IP across different devices', () async {
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

    final future = coordinator.runAuthAndVersion(2);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    // 两台不同类型设备共用同一 IP：都保留，且 IP 标记（重复）。
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));
    transport.emitBytes(_authAck('MMR200', '192.168.1.10'));

    await _waitForStep(controller, 2, StepStatus.running);
    transport.emitBytes(_versionOk('MR9360', '192.168.1.10', '0.0.0.1'));
    transport.emitBytes(_versionOk('MMR200', '192.168.1.10', '0.0.0.2'));

    await future;

    expect(controller.devices.length, 2);
    expect(controller.devices[0].ip, '192.168.1.10（重复）');
    expect(controller.devices[1].ip, '192.168.1.10（重复）');
    expect(controller.devices[0].type, 'MR9360');
    expect(controller.devices[1].type, 'MMR200');
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

    final future = coordinator.runAuthAndVersion(1);

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

  test(
    'version_fail marks device as unable to fetch with translated reason',
    () async {
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

      final future = coordinator.runAuthAndVersion(1);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      transport.emitBytes(_authAck('MR9360', '192.168.1.10'));

      await _waitForStep(controller, 2, StepStatus.running);
      transport.emitBytes(_versionFail('MR9360', '192.168.1.10', 'format'));

      await future;

      expect(controller.devices.single.status, '无法获取');
      expect(controller.devices.single.result, '版本号格式非法');
      expect(controller.activeStep, 3);
      expect(controller.transferStage, TransferStage.notStarted);
    },
  );

  test('auth with no devices enters recoverable failure state', () async {
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

    await coordinator.runAuthAndVersion(1);

    expect(controller.phase, UpdatePhase.authFailed);
    expect(controller.summary, '认证失败：设备认证数量为 0');
    expect(controller.steps[1].status, StepStatus.failed);
    expect(transport.closed, isFalse);
  });

  test('auth retries across windows until reaching expected count', () async {
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
      authTimeout: const Duration(milliseconds: 60),
      versionTimeout: const Duration(milliseconds: 60),
    );

    final future = coordinator.runAuth(2);

    // 第一个窗口（0~60ms）不回复；第二个窗口（60~120ms）回复两台。
    await Future<void>.delayed(const Duration(milliseconds: 80));
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));
    transport.emitBytes(_authAck('MMR200', '192.168.1.11'));

    final result = await future;
    expect(result, isTrue);
    expect(controller.steps[1].status, StepStatus.success);
    expect(controller.devices.length, 2);
  });

  test('auth succeeds with partial devices after windows exhausted', () async {
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
      authTimeout: const Duration(milliseconds: 40),
      versionTimeout: const Duration(milliseconds: 40),
    );

    final future = coordinator.runAuth(2);

    // 前两个窗口不回复，最后一个窗口只回复 1 台（> 0 但 < 2）→ 仍转绿。
    await Future<void>.delayed(const Duration(milliseconds: 90));
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));

    final result = await future;
    expect(result, isTrue);
    expect(controller.steps[1].status, StepStatus.success);
    expect(controller.devices.length, 1);
  });

  test('reAuth clears devices and recovers into version check', () async {
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
      authTimeout: const Duration(milliseconds: 30),
      versionTimeout: const Duration(milliseconds: 80),
    );

    await coordinator.runAuth(1);
    expect(controller.phase, UpdatePhase.authFailed);
    expect(controller.steps[1].status, StepStatus.failed);

    final reAuthFuture = coordinator.reAuth(1);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    transport.emitBytes(_authAck('MR9360', '192.168.1.10'));

    await _waitForStep(controller, 2, StepStatus.running);
    transport.emitBytes(_versionOk('MR9360', '192.168.1.10', '0.0.0.1'));

    await reAuthFuture;

    expect(controller.steps[1].status, StepStatus.success);
    expect(controller.devices.length, 1);
    expect(controller.activeStep, 3);
    expect(controller.phase, UpdatePhase.running);
  });

  test('version check retries across windows until all devices reply', () async {
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
    controller.devices.addAll([
      UpdateDevice(ip: '192.168.1.10', type: 'MR9360'),
      UpdateDevice(ip: '192.168.1.11', type: 'MMR200'),
    ]);
    final coordinator = UpdateFlowCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      targetVersion: '0.1.1.1',
      versionTimeout: const Duration(milliseconds: 50),
    );

    final future = coordinator.runVersionCheck();

    // 第一个窗口（0~50ms）不回复；第二个窗口（50~100ms）回复两台。
    await Future<void>.delayed(const Duration(milliseconds: 70));
    transport.emitBytes(_versionOk('MR9360', '192.168.1.10', '0.0.0.1'));
    transport.emitBytes(_versionOk('MMR200', '192.168.1.11', '0.0.0.2'));

    final result = await future;
    expect(result, isTrue);
    expect(controller.steps[2].status, StepStatus.success);
    expect(controller.devices[0].currentVersion, '0.0.0.1');
    expect(controller.devices[1].currentVersion, '0.0.0.2');
    expect(controller.activeStep, 3);
  });

  test('version check with no replies enters recoverable failure', () async {
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
    controller.devices.add(UpdateDevice(ip: '192.168.1.10', type: 'MR9360'));
    final coordinator = UpdateFlowCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      targetVersion: '0.1.1.1',
      versionTimeout: const Duration(milliseconds: 20),
    );

    final result = await coordinator.runVersionCheck();

    expect(result, isFalse);
    expect(controller.phase, UpdatePhase.versionFailed);
    expect(controller.steps[2].status, StepStatus.failed);
    expect(controller.summary, '版本校验失败：设备回复数量为 0');
    expect(transport.closed, isFalse);
  });

  test('reVersionCheck clears version columns and recovers', () async {
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
    controller.devices.add(
      UpdateDevice(ip: '192.168.1.10', type: 'MR9360')
        ..currentVersion = '0.0.0.9'
        ..newVersion = '0.9.9.9'
        ..status = '需更新'
        ..result = 'stale',
    );
    final coordinator = UpdateFlowCoordinator(
      session: session,
      controller: controller,
      storage: storage,
      baseName: 'install_xxx',
      targetVersion: '0.1.1.1',
      versionTimeout: const Duration(milliseconds: 20),
    );

    // 首次校验失败（0 回复）。
    await coordinator.runVersionCheck();
    expect(controller.phase, UpdatePhase.versionFailed);

    // 重新版本校验成功。
    final reVersionFuture = coordinator.reVersionCheck();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    transport.emitBytes(_versionOk('MR9360', '192.168.1.10', '0.0.0.1'));
    await reVersionFuture;

    expect(controller.steps[2].status, StepStatus.success);
    expect(controller.devices[0].currentVersion, '0.0.0.1');
    expect(controller.devices[0].status, '需更新');
    expect(controller.activeStep, 3);
    expect(controller.phase, UpdatePhase.running);
  });
}
