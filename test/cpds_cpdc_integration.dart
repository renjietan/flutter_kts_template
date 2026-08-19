import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/core/cpds/parser/cpds_package_parser.dart';
import 'package:flutter_kts_template/core/cpds/protocol/cpds_udp_transport.dart';
import 'package:flutter_kts_template/core/cpds/service/cpds_network_interfaces.dart';
import 'package:flutter_kts_template/core/cpds/session/cpds_session_machine.dart';
import 'package:flutter_kts_template/core/cpds/session/cpds_session_runner.dart';

Future<void> main() async {
  const zipPath = r'D:\work\flutter\template\3-38-10\CPDS-main\build\dist\bin\8-12-valid.zip';
  const fileName = '8-12-valid.zip';
  const nodeId = 'nn_hytis_8194';

  final interfaces = await CpdsNetworkInterfaceService.listWiredInterfaces();
  final selected = interfaces.firstWhere(
    (item) => item.name.toLowerCase().contains('wlan'),
    orElse: () => interfaces.first,
  );
  stdout.writeln('SELECTED_INTERFACE ${selected.name} ${selected.ipv4}');

  final package = await CpdsPackageParser.parseFile(zipPath, fileName);
  final file = File(zipPath);
  final bytes = await file.readAsBytes();
  final sha = sha256.convert(bytes).bytes;

  final machine = CpdsSessionMachine(
    nodeId: nodeId,
    expected: [
      const CpdsDevice(
        id: 'dc_PMR200_978256516',
        type: CpdsDeviceType.multiBandHandheld,
        model: 'PMR200',
        alias: '03',
        ip: '10.3.0.134',
      ),
    ],
  );
  final sessionId = Uint8List.fromList(
    List<int>.generate(16, (_) => Random.secure().nextInt(256)),
  );
  sessionId[6] = (sessionId[6] & 0x0F) | 0x40;
  sessionId[8] = (sessionId[8] & 0x3F) | 0x80;
  machine.begin(sessionId);

  final transport = CpdsUdpTransport();
  await transport.init(interfaceIp: selected.ipv4);
  final decisionController = StreamController<bool>.broadcast();
  final runner = CpdsSessionRunner(
    transport: transport,
    machine: machine,
    input: CpdsPackageInput(
      fileName: fileName,
      filePath: zipPath,
      fileSize: file.lengthSync(),
      sha256: Uint8List.fromList(sha),
      expandedSize: package.expandedSize,
      requiredWorkspace: package.requiredWorkspace,
    ),
    discoveryDecision: decisionController.stream,
    onUpdate: (view) {
      stdout.writeln(
        'STATE ${view.activeState.apiName} '
        'sent=${view.sentChunks}/${view.totalChunks} '
        'failures=${view.failures.length}',
      );
    },
  );

  await runner.run().timeout(const Duration(seconds: 45));
  final view = machine.view();
  stdout.writeln(
    'FINAL_STATE ${view.activeState.apiName} '
    'devices=${view.devices.map((d) => d.status.apiName).toList()}',
  );
  for (final failure in view.failures) {
    stdout.writeln(
      'FAILURE stage=${failure.stage} deviceType=${failure.deviceType.apiName} '
      'code=${failure.errorCode.apiName} params=${failure.params}',
    );
  }
  await decisionController.close();
  await transport.dispose();
}
