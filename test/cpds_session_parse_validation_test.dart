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

Map<int, dynamic> _body({
  int deviceType = 1,
  int typeResult = 1,
  int stage = 0,
  int typeErrorCode = 0,
  int result = 1,
  int errorCode = 0,
}) {
  return {
    1: _identity(),
    2: result,
    3: 'nn_1',
    4: [
      {1: CpdsDeviceType.server.value, 2: 'dev_1'},
    ],
    5: [
      {1: deviceType, 2: 'dev_1', 3: typeResult, 4: stage, 5: typeErrorCode},
    ],
    6: errorCode,
  };
}

Future<void> main() async {
  await _testValidSuccess();
  await _testValidFailure();
  await _testRejectTypeMismatch();
  await _testRejectSuccessWithErrorCode();
  await _testRejectFailureWithoutErrorCode();
  await _testRejectFailureWithoutFailedType();
  stdout.writeln('CPDS_PARSE_VALIDATION_OK');
}

Future<void> _testValidSuccess() async {
  final machine = _transferringMachine();
  machine.recordParseComplete(_body());
  if (machine.state != CpdsActiveState.completed) {
    throw StateError('valid success parse should complete');
  }
}

Future<void> _testValidFailure() async {
  final machine = _transferringMachine();
  machine.recordParseComplete(
    _body(
      result: CpdResult.failed.value,
      errorCode: CpdsErrorCode.outputWriteFailed.value,
      typeResult: CpdResult.failed.value,
      stage: CpdParseStage.writeOutput.value,
      typeErrorCode: CpdsErrorCode.outputWriteFailed.value,
    ),
  );
  if (machine.state != CpdsActiveState.failed) {
    throw StateError('valid failure parse should fail');
  }
}

Future<void> _testRejectTypeMismatch() async {
  final machine = _transferringMachine();
  machine.recordParseComplete(_body(deviceType: CpdsDeviceType.ccu.value));
  _assertDropped(machine);
}

Future<void> _testRejectSuccessWithErrorCode() async {
  final machine = _transferringMachine();
  machine.recordParseComplete(
    _body(errorCode: CpdsErrorCode.invalidMessage.value),
  );
  _assertDropped(machine);
}

Future<void> _testRejectFailureWithoutErrorCode() async {
  final machine = _transferringMachine();
  machine.recordParseComplete(
    _body(
      result: CpdResult.failed.value,
      typeResult: CpdResult.failed.value,
      stage: CpdParseStage.writeOutput.value,
      typeErrorCode: CpdsErrorCode.outputWriteFailed.value,
    ),
  );
  _assertDropped(machine);
}

Future<void> _testRejectFailureWithoutFailedType() async {
  final machine = _transferringMachine();
  machine.recordParseComplete(
    _body(
      result: CpdResult.failed.value,
      errorCode: CpdsErrorCode.outputWriteFailed.value,
    ),
  );
  _assertDropped(machine);
}

void _assertDropped(CpdsSessionMachine machine) {
  if (machine.state != CpdsActiveState.transferring) {
    throw StateError('invalid parse should be dropped, got ${machine.state}');
  }
  if (machine.view().devices.single.status != CpdsDeviceStatus.authenticated) {
    throw StateError('device should remain authenticated');
  }
}

CpdsSessionMachine _transferringMachine() {
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
  machine.recordDiscovery(
    _esn,
    _nonce,
    const [CpdsDeviceType.server],
    '10.0.0.2',
    '255.255.255.0',
  );
  machine.finishDiscovery();
  machine.recordAuth({
    1: _identity(),
    2: CpdResult.success.value,
    3: 'nn_1',
    4: [
      {1: CpdsDeviceType.server.value, 2: 'dev_1'},
    ],
  });
  return machine;
}
