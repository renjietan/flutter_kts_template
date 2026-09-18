import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/parser/cpds_package_parser.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final tempDir = await Directory.systemTemp.createTemp('cpds_smoke_');
  final zipPath = p.join(tempDir.path, 'valid.zip');

  final archive = Archive();
  archive.addFile(
    _jsonFile('0_contacts/contacts_1.json', {
      'File': {'Guid': 'guid-contact', 'Model': 'model'},
      'UnitTree': {
        'UnitId': 'unit_1',
        'NetNodes': ['nn_1'],
        'SubUnits': [],
      },
    }),
  );
  archive.addFile(
    _jsonFile('6_unit/unit_1.json', {
      'File': {'Guid': 'guid-unit', 'Model': 'model'},
      'UnitName': 'TestUnit',
    }),
  );
  archive.addFile(
    _jsonFile('4_net_node/nn_1.json', {
      'BasicInfo': {
        'NetworkSegment': '10.0.0.0/24',
        'NodeName': 'NodeA',
        'NodeType': 1,
      },
      'File': {'Guid': 'guid-node', 'Model': 'Vehicle'},
      'SystemConfiguration': {
        'LANPrimary': {
          'Server': ['dc_server_test'],
        },
        'LANMember': {
          'CCU': ['dc_ccu_test'],
          'VehInter': ['dc_VehInter_test'],
        },
        'Radio': {},
      },
    }),
  );
  archive.addFile(
    _jsonFile('3_device_config/dc_ccu_test.json', {
      'File': {'Guid': 'guid-device', 'Model': 'CCU-Test'},
      'Alias': 'CCU-1',
      'IP': '10.0.0.9',
      'Channels': {},
      'controlBoardIpConfig': {
        'result': {'ip1': '10.0.0.11', 'ip2': '10.0.0.12'},
      },
      'audioBoardIpConfig': {
        'result': {'ip': '10.0.0.13'},
      },
    }),
  );
  archive.addFile(
    _jsonFile('3_device_config/dc_server_test.json', {
      'File': {'Guid': 'guid-device', 'Model': 'Server'},
      'Ipv4Subnet': '10.0.0.21',
    }),
  );
  archive.addFile(
    _jsonFile('3_device_config/dc_VehInter_test.json', {
      'File': {'Guid': 'guid-device', 'Model': 'VehInter'},
      'CTIP': '10.0.0.31',
    }),
  );

  final bytes = ZipEncoder().encode(archive);
  await File(zipPath).writeAsBytes(bytes);

  final package = await CpdsPackageParser.parseFile(zipPath, 'valid.zip');
  if (package.units.length != 1 ||
      package.units.first.name != 'TestUnit' ||
      package.units.first.nodeIds.single != 'nn_1') {
    throw StateError('unit tree mismatch: ${jsonEncode(package.units)}');
  }
  final node = package.nodes.singleWhere((item) => item.id == 'nn_1');
  if (node.name != 'NodeA') {
    throw StateError('node name mismatch: ${node.name}');
  }
  final ccuMain = node.devices.where((d) => d.type == CpdsDeviceType.ccu);
  final ccuAudio = node.devices.where((d) => d.type == CpdsDeviceType.ccuAudio);
  if (ccuMain.length != 1 || ccuAudio.length != 1) {
    throw StateError(
      'expected one CCU and one CCU-Audio, got '
      '${ccuMain.length}/${ccuAudio.length}',
    );
  }

  final ccuMainDevice = ccuMain.single;
  final ccuAudioDevice = ccuAudio.single;
  if (ccuMainDevice.distributionIp1 != '10.0.0.11' ||
      ccuMainDevice.distributionIp2 != '10.0.0.12') {
    throw StateError(
      'ccu-main distribution ips mismatch: '
      '${ccuMainDevice.distributionIp1}/${ccuMainDevice.distributionIp2}',
    );
  }
  if (ccuAudioDevice.distributionIp1 != '10.0.0.13' ||
      ccuAudioDevice.distributionIp2.isNotEmpty) {
    throw StateError('ccu-audio distribution ip mismatch');
  }
  final server = node.devices.singleWhere(
    (d) => d.type == CpdsDeviceType.server,
  );
  if (server.distributionIp1 != '10.0.0.21' ||
      server.distributionIp2.isNotEmpty) {
    throw StateError('server distribution ip mismatch');
  }
  final vehInter = node.devices.singleWhere(
    (d) => d.type == CpdsDeviceType.vehInter,
  );
  if (vehInter.distributionIp1 != '10.0.0.31' ||
      vehInter.distributionIp2.isNotEmpty) {
    throw StateError('vehInter distribution ip mismatch');
  }

  stdout.writeln(
    'VALID_ZIP_OK nodes=${package.nodes.length} devices=${node.devices.length}',
  );

  final invalidArchive = Archive();
  invalidArchive.addFile(
    _jsonFile('0_contacts/contacts_1.json', {
      'File': {},
      'UnitTree': {'UnitId': 'unit_1', 'NetNodes': [], 'SubUnits': []},
    }),
  );
  final invalidBytes = ZipEncoder().encode(invalidArchive);
  final invalidPath = p.join(tempDir.path, 'invalid.zip');
  await File(invalidPath).writeAsBytes(invalidBytes);

  var invalidRejected = false;
  try {
    await CpdsPackageParser.parseFile(invalidPath, 'invalid.zip');
  } on CpdsException catch (error) {
    invalidRejected =
        error.code == CpdsErrorCode.invalidPackage &&
        error.params['field'] == 'requiredDirectory';
  }
  if (!invalidRejected) {
    throw StateError('invalid package was not rejected as expected');
  }
  stdout.writeln('INVALID_ZIP_REJECTED_OK');

  await tempDir.delete(recursive: true);
}

ArchiveFile _jsonFile(String name, Map<String, dynamic> data) {
  return ArchiveFile.bytes(name, utf8.encode(jsonEncode(data)));
}
