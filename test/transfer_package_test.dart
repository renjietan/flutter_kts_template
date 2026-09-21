import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('buildTypeZip packs only the selected type folders', () async {
    final tempDir = await Directory.systemTemp.createTemp('build_zip_test');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final installDir = Directory(p.join(tempDir.path, 'install'));
    final storage = InstallPackageStorage(installDirectory: installDir);

    for (final type in ['MR9360', 'MMR200', 'CCU']) {
      final dir = Directory(p.join(installDir.path, 'install_xxx', type));
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'cpdc_config.json')).writeAsString(
        '{"version":"0.1.1.1"}',
      );
    }

    final zip = await storage.buildTypeZip(
      baseName: 'install_xxx',
      deviceTypes: {'MR9360', 'MMR200'},
    );

    final archive = ZipDecoder().decodeBytes(zip);
    final names = archive.map((f) => f.name).toList();
    expect(names, contains('MR9360/cpdc_config.json'));
    expect(names, contains('MMR200/cpdc_config.json'));
    expect(names.any((n) => n.startsWith('CCU/')), isFalse);
  });

  test('splitPackets splits into max-1400-byte packets with 1-based numbers', () {
    final data = Uint8List.fromList(
      List.generate(3000, (i) => i % 256),
    );

    final packets = UpdateProtocol.splitPackets(data);

    expect(packets.length, 3);
    for (final packet in packets) {
      expect(packet.length, lessThanOrEqualTo(UpdateProtocol.maxDatagramBytes));
      expect(String.fromCharCodes(packet.sublist(0, 7)), 'packet:');
    }

    final rebuilt = BytesBuilder();
    for (var i = 0; i < packets.length; i++) {
      final packet = packets[i];
      final view = ByteData.sublistView(packet);
      expect(view.getUint32(11, Endian.big), i + 1); // 包号
      final length = view.getUint32(15, Endian.big); // 分包长度
      final payload = packet.sublist(19, 19 + length);
      expect(view.getUint32(7, Endian.big), UpdateProtocol.crc32(payload));
      rebuilt.add(payload);
    }
    expect(rebuilt.toBytes(), data);
  });
}
