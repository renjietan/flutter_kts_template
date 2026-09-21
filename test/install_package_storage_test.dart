import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Uint8List _buildZip(Map<String, Uint8List> files) {
  final archive = Archive();
  final topDirs = <String>{};
  for (final name in files.keys) {
    final parts = name.split('/');
    if (parts.length > 1) {
      topDirs.add(parts.first);
    }
  }
  for (final dir in topDirs) {
    archive.addFile(ArchiveFile.directory('$dir/'));
  }
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory tempDir;
  late InstallPackageStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('install_storage_test');
    storage = InstallPackageStorage(installDirectory: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('formatBaseName produces install_yyyyMMdd_HHmmss', () {
    expect(
      InstallPackageStorage.formatBaseName(DateTime(2026, 9, 19, 12, 34, 56)),
      'install_20260919_123456',
    );
  });

  test('multiple folders are wrapped into the baseName folder', () async {
    final baseName = 'install_20260919_123456';
    await storage.saveZip(
      _buildZip({
        'CPDC-CCU/CPDC-CCU': Uint8List.fromList([1]),
        'CPDC-CCU-Audio/CPDC-CCU-Audio': Uint8List.fromList([2]),
      }),
      baseName: baseName,
    );

    final dir = await storage.extractZip(baseName: baseName);

    expect(dir.path, p.join(tempDir.path, baseName));
    expect(Directory(p.join(dir.path, 'CPDC-CCU')).existsSync(), isTrue);
    expect(Directory(p.join(dir.path, 'CPDC-CCU-Audio')).existsSync(), isTrue);
    expect(File(p.join(dir.path, 'CPDC-CCU', 'CPDC-CCU')).existsSync(), isTrue);
  });

  test('single folder is renamed to the baseName', () async {
    final baseName = 'install_20260919_123456';
    await storage.saveZip(
      _buildZip({
        'CPDC-CCU/CPDC-CCU': Uint8List.fromList([1]),
      }),
      baseName: baseName,
    );

    final dir = await storage.extractZip(baseName: baseName);

    expect(dir.path, p.join(tempDir.path, baseName));
    expect(Directory(p.join(dir.path, 'CPDC-CCU')).existsSync(), isFalse);
    expect(File(p.join(dir.path, 'CPDC-CCU')).existsSync(), isTrue);
  });

  test('delete removes both the zip and the extracted folder', () async {
    final baseName = 'install_20260919_123456';
    await storage.saveZip(
      _buildZip({
        'CPDC-CCU/CPDC-CCU': Uint8List.fromList([1]),
      }),
      baseName: baseName,
    );
    await storage.extractZip(baseName: baseName);

    await storage.delete(baseName: baseName);

    expect(File(p.join(tempDir.path, '$baseName.zip')).existsSync(), isFalse);
    expect(Directory(p.join(tempDir.path, baseName)).existsSync(), isFalse);
  });

  test('packageExists reports zip or folder presence', () async {
    final baseName = 'install_20260919_123456';
    final fileName = '$baseName.zip';

    expect(await storage.packageExists(fileName), isFalse);

    await storage.saveZip(
      _buildZip({'CPDC-CCU/CPDC-CCU': Uint8List.fromList([1])}),
      baseName: baseName,
    );
    expect(await storage.packageExists(fileName), isTrue);

    await storage.delete(baseName: baseName);
    expect(await storage.packageExists(fileName), isFalse);
  });

  test(
    'nested folders are preserved when the single folder is renamed',
    () async {
      final baseName = 'install_20260919_123456';
      await storage.saveZip(
        _buildZip({
          'CPDC-CCU/sub/CPDC-CCU': Uint8List.fromList([1]),
        }),
        baseName: baseName,
      );

      final dir = await storage.extractZip(baseName: baseName);

      expect(dir.path, p.join(tempDir.path, baseName));
      expect(File(p.join(dir.path, 'sub', 'CPDC-CCU')).existsSync(), isTrue);
      expect(Directory(p.join(dir.path, 'CPDC-CCU')).existsSync(), isFalse);
    },
  );

  test('mixed root content (file and folder) is wrapped together', () async {
    final baseName = 'install_20260919_123456';
    await storage.saveZip(
      _buildZip({
        'README.txt': Uint8List.fromList([1]),
        'CPDC-CCU/CPDC-CCU': Uint8List.fromList([2]),
      }),
      baseName: baseName,
    );

    final dir = await storage.extractZip(baseName: baseName);

    expect(File(p.join(dir.path, 'README.txt')).existsSync(), isTrue);
    expect(Directory(p.join(dir.path, 'CPDC-CCU')).existsSync(), isTrue);
    expect(File(p.join(dir.path, 'CPDC-CCU', 'CPDC-CCU')).existsSync(), isTrue);
  });

  test('empty zip creates an empty baseName folder', () async {
    final baseName = 'install_20260919_123456';
    await storage.saveZip(_buildZip({}), baseName: baseName);

    final dir = await storage.extractZip(baseName: baseName);

    expect(dir.path, p.join(tempDir.path, baseName));
    expect(dir.existsSync(), isTrue);
    expect(dir.listSync(), isEmpty);
  });

  test('single file is moved into the baseName folder', () async {
    final baseName = 'install_20260919_123456';
    await storage.saveZip(
      _buildZip({'readme.txt': Uint8List.fromList([1, 2, 3])}),
      baseName: baseName,
    );

    final dir = await storage.extractZip(baseName: baseName);

    expect(dir.path, p.join(tempDir.path, baseName));
    expect(File(p.join(dir.path, 'readme.txt')).existsSync(), isTrue);
  });

  test('re-extracting the same baseName removes stale content', () async {
    final baseName = 'install_20260919_123456';
    await storage.saveZip(
      _buildZip({
        'A/a.txt': Uint8List.fromList([1]),
        'B/b.txt': Uint8List.fromList([2]),
      }),
      baseName: baseName,
    );
    await storage.extractZip(baseName: baseName);

    await storage.saveZip(
      _buildZip({'C/c.txt': Uint8List.fromList([3])}),
      baseName: baseName,
    );
    final dir = await storage.extractZip(baseName: baseName);

    expect(Directory(p.join(dir.path, 'A')).existsSync(), isFalse);
    expect(Directory(p.join(dir.path, 'B')).existsSync(), isFalse);
    expect(File(p.join(dir.path, 'c.txt')).existsSync(), isTrue);
  });
}
