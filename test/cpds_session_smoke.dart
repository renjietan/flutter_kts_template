import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/cpds/protocol/cpd_protocol.dart';
import 'package:flutter_kts_template/core/cpds/session/cpds_session_machine.dart';

Future<void> main() async {
  final sessionId = Uint8List.fromList(List<int>.generate(16, (i) => i));
  final machine = CpdsSessionMachine(
    nodeId: 'nn_1',
    expected: [
      const CpdsDevice(
        id: 'dev_1',
        type: CpdsDeviceType.server,
        model: 'Server',
        alias: '',
        ip: '10.0.0.10',
      ),
    ],
  );
  machine.begin(sessionId);

  final esn = '123456789012345678901234567890123456789';
  final nonce = Uint8List.fromList(List<int>.generate(16, (i) => i + 20));
  machine.recordDiscovery(
    esn,
    nonce,
    const [CpdsDeviceType.server],
    '10.0.0.2',
    '255.255.255.0',
  );
  machine.finishDiscovery();
  if (machine.state != CpdsActiveState.authenticating) {
    throw StateError('expected authenticating, got ${machine.state}');
  }

  final clientIdentity = <int, dynamic>{
    1: esn,
    2: CpdPackedEnums([CpdsDeviceType.server.value]),
  };
  machine.recordAuth({
    1: clientIdentity,
    2: CpdResult.success.value,
    3: 'nn_1',
    4: [
      {
        1: CpdsDeviceType.server.value,
        2: 'dev_1',
      },
    ],
  });
  if (machine.state != CpdsActiveState.transferring) {
    throw StateError('expected transferring, got ${machine.state}');
  }

  machine.beginTransferWait(DateTime.now());
  machine.recordTransferComplete({
    1: clientIdentity,
    2: CpdResult.success.value,
    3: CpdTransferStage.cacheReuse.value,
    4: 0,
    5: CpdsErrorCode.unspecified.value,
  });
  if (machine.state != CpdsActiveState.waitingParse) {
    throw StateError('expected waitingParse, got ${machine.state}');
  }

  machine.recordParseComplete({
    1: clientIdentity,
    2: CpdResult.success.value,
    3: 'nn_1',
    4: [
      {
        1: CpdsDeviceType.server.value,
        2: 'dev_1',
      },
    ],
    5: [
      {
        1: CpdsDeviceType.server.value,
        2: 'dev_1',
        3: CpdResult.success.value,
        4: CpdParseStage.unspecified.value,
        5: CpdsErrorCode.unspecified.value,
      },
    ],
    6: CpdsErrorCode.unspecified.value,
  });

  if (machine.state != CpdsActiveState.completed) {
    throw StateError('expected completed, got ${machine.state}');
  }
  final view = machine.view();
  if (view.devices.single.status != CpdsDeviceStatus.completed) {
    throw StateError('device did not complete');
  }

  final packet = CpdPacket(
    sessionId: sessionId,
    messageId: Uint8List.fromList(List<int>.generate(16, (i) => i + 30)),
    bodyField: 10,
    body: const {1: 'abc'},
  );
  final datagram = CpdProtocol.encodePacket(packet);
  final decoded = CpdProtocol.decodePacket(datagram);
  if (decoded == null ||
      decoded.bodyField != 10 ||
      String.fromCharCodes(decoded.body[1] as Uint8List) != 'abc') {
    throw StateError('protocol roundtrip failed');
  }

  stdout.writeln('SESSION_STATE_MACHINE_OK');
  stdout.writeln('PROTOCOL_ROUNDTRIP_OK');
}
