import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/cpds/protocol/cpd_protocol.dart';
import 'package:flutter_kts_template/core/cpds/session/cpds_session_machine.dart';

const _esn = '123456789012345678901234567890123456789';

final _sessionId = Uint8List.fromList(List<int>.generate(16, (i) => i));
final _nonce = Uint8List.fromList(List<int>.generate(16, (i) => i + 20));

Map<int, dynamic> _identity() => {
  1: _esn,
  2: CpdPackedEnums([CpdsDeviceType.server.value]),
};

Future<void> main() async {
  await _testLossPackRangeMerge();
  await _testAuthFailedRequiresErrorCode();
  await _testAuthSuccessRejectsErrorCode();
  await _testSubnetMaskContiguity();
  await _testDiscoveryDuplicateTypeConsistency();
  stdout.writeln('CPDS_VALIDATION_OK');
}

Future<void> _testLossPackRangeMerge() async {
  final machine = _transferringMachine();
  machine.setSendProgress(0, 100, 0, false);
  machine.beginTransferWait(DateTime.now());
  final accepted = machine.recordLossPack({
    1: _identity(),
    2: [
      {1: 10, 2: 20},
      {1: 15, 2: 25},
    ],
  });
  if (!accepted) {
    throw StateError('loss pack was not accepted');
  }
  final status = machine.view().devices.single;
  if (status.receivedChunks != 84) {
    throw StateError(
      'expected merged received 84, got ${status.receivedChunks}',
    );
  }
}

Future<void> _testAuthFailedRequiresErrorCode() async {
  final machine = _authenticatingMachine();
  machine.recordAuth({1: _identity(), 2: CpdResult.failed.value});
  if (machine.state != CpdsActiveState.authenticating) {
    throw StateError('failed auth without error code should be dropped');
  }
  if (machine.view().devices.single.status == CpdsDeviceStatus.failed) {
    throw StateError('device should not be failed');
  }
}

Future<void> _testAuthSuccessRejectsErrorCode() async {
  final machine = _authenticatingMachine();
  machine.recordAuth({
    1: _identity(),
    2: CpdResult.success.value,
    3: 'nn_1',
    4: [
      {1: CpdsDeviceType.server.value, 2: 'dev_1'},
    ],
    5: CpdsErrorCode.invalidMessage.value,
  });
  if (machine.state != CpdsActiveState.failed) {
    throw StateError('success auth with error code should fail');
  }
  if (machine.view().devices.single.errorCode !=
      CpdsErrorCode.authBindingMissing) {
    throw StateError('expected authBindingMissing on success with error code');
  }
}

Future<void> _testSubnetMaskContiguity() async {
  final machine = _discoveringMachine();
  machine.recordDiscovery(
    _esn,
    _nonce,
    const [CpdsDeviceType.server],
    '10.0.0.2',
    '255.0.255.0',
  );
  machine.finishDiscovery();
  if (machine.state != CpdsActiveState.failed) {
    throw StateError('non-contiguous subnet mask should fail discovery');
  }
}

Future<void> _testDiscoveryDuplicateTypeConsistency() async {
  final machine = _discoveringMachine();
  machine.recordDiscovery(
    _esn,
    _nonce,
    const [CpdsDeviceType.server],
    '10.0.0.2',
    '255.255.255.0',
  );
  machine.recordDiscovery(
    _esn,
    _nonce,
    const [CpdsDeviceType.ccu],
    '10.0.0.2',
    '255.255.255.0',
  );
  machine.finishDiscovery();
  if (machine.state != CpdsActiveState.failed) {
    throw StateError('duplicate discovery with different types should fail');
  }
}

CpdsSessionMachine _discoveringMachine() {
  final machine = CpdsSessionMachine(
    nodeId: 'nn_1',
    expected: const [
      CpdsDevice(
        id: 'dev_1',
        type: CpdsDeviceType.server,
        model: 'Server',
        alias: '',
        ip: '10.0.0.10',
      ),
    ],
  );
  machine.begin(_sessionId);
  return machine;
}

CpdsSessionMachine _authenticatingMachine() {
  final machine = _discoveringMachine();
  machine.recordDiscovery(
    _esn,
    _nonce,
    const [CpdsDeviceType.server],
    '10.0.0.2',
    '255.255.255.0',
  );
  machine.finishDiscovery();
  if (machine.state != CpdsActiveState.authenticating) {
    throw StateError('expected authenticating state');
  }
  return machine;
}

CpdsSessionMachine _transferringMachine() {
  final machine = _authenticatingMachine();
  machine.recordAuth({
    1: _identity(),
    2: CpdResult.success.value,
    3: 'nn_1',
    4: [
      {1: CpdsDeviceType.server.value, 2: 'dev_1'},
    ],
  });
  if (machine.state != CpdsActiveState.transferring) {
    throw StateError('expected transferring state');
  }
  return machine;
}
