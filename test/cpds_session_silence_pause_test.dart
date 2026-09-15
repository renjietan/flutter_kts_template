import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/cpds/protocol/cpd_protocol.dart';
import 'package:flutter_kts_template/core/cpds/session/cpds_session_machine.dart';

Future<void> main() async {
  final paused = _transferringMachine();
  final t0 = DateTime(2026, 1, 1, 0, 0, 0);
  paused.machine.beginTransferWait(t0);

  final t1 = t0.add(const Duration(seconds: 5));
  paused.machine.setRetransmitting(paused.esn, true, t1);

  // 补发期间即使超过 10 秒静默上限，也不应误判为静默失败。
  final t2 = t1.add(const Duration(seconds: 11));
  paused.machine.checkDeadlines(t2);
  if (paused.machine.view().devices.single.status == CpdsDeviceStatus.failed) {
    throw StateError('silence timeout fired while retransmitting');
  }

  // 解除暂停会把静默计时顺延，随后短时间内不应触发静默失败。
  paused.machine.setRetransmitting(paused.esn, false, t2);
  final t3 = t2.add(const Duration(seconds: 1));
  paused.machine.checkDeadlines(t3);
  if (paused.machine.view().devices.single.status == CpdsDeviceStatus.failed) {
    throw StateError('silence timeout fired right after unpausing');
  }

  // 对照组：未暂停时，超过 10 秒静默应正常触发静默失败。
  final control = _transferringMachine();
  final c0 = DateTime(2026, 1, 1, 0, 0, 0);
  control.machine.beginTransferWait(c0);
  control.machine.checkDeadlines(c0.add(const Duration(seconds: 11)));
  final controlStatus = control.machine.view().devices.single.status;
  if (controlStatus != CpdsDeviceStatus.failed) {
    throw StateError('expected silence timeout in control, got $controlStatus');
  }

  stdout.writeln('SILENCE_PAUSE_OK');
}

({CpdsSessionMachine machine, String esn}) _transferringMachine() {
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
  machine.begin(Uint8List.fromList(List<int>.generate(16, (i) => i)));

  const esn = '123456789012345678901234567890123456789';
  machine.recordDiscovery(
    esn,
    Uint8List.fromList(List<int>.generate(16, (i) => i + 20)),
    const [CpdsDeviceType.server],
    '10.0.0.2',
    '255.255.255.0',
  );
  machine.finishDiscovery();
  machine.recordAuth({
    1: {
      1: esn,
      2: CpdPackedEnums([CpdsDeviceType.server.value]),
    },
    2: CpdResult.success.value,
    3: 'nn_1',
    4: [
      {1: CpdsDeviceType.server.value, 2: 'dev_1'},
    ],
  });
  return (machine: machine, esn: esn);
}
