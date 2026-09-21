import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_repository.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/self_update_service.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late Store store;
  late InstallPackageRepository repository;
  late InstallPackageStorage storage;
  late SelfUpdateService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('self_update_service_test');
    store = await openStore(directory: tempDir.path);
    repository = InstallPackageRepository(store.box<InstallPackageEntity>());
    storage = InstallPackageStorage(
      installDirectory: Directory(p.join(tempDir.path, 'install')),
    );
    service = SelfUpdateService(repository: repository, storage: storage);
  });

  tearDown(() {
    store.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('uploadZip saves, extracts, and returns the zip file name', () async {
    final fileName = await service.uploadZip(
      Uint8List.fromList([0x50, 0x4B, 0x05, 0x06, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      now: DateTime(2026, 9, 19, 12, 34, 56),
    );

    expect(fileName, 'install_20260919_123456.zip');
    expect(
      File(p.join(tempDir.path, 'install', fileName)).existsSync(),
      isTrue,
    );
    expect(
      Directory(p.join(tempDir.path, 'install', 'install_20260919_123456'))
          .existsSync(),
      isTrue,
    );
  });

  test('savePackage inserts and overwrites on same version', () async {
    await service.savePackage(
      version: '0.1.1.1',
      fileName: 'a.zip',
      remark: 'first',
      createdAt: DateTime(2026, 1, 1),
    );
    await service.savePackage(
      version: '0.1.1.1',
      fileName: 'b.zip',
      remark: 'second',
      createdAt: DateTime(2026, 1, 2),
    );

    expect(repository.count(), 1);
    final saved = repository.findByVersion('0.1.1.1')!;
    expect(saved.fileName, 'b.zip');
    expect(saved.remark, 'second');
    expect(saved.createdAt, DateTime(2026, 1, 2));
  });

  test('updatePackage edits version and remark and keeps file name', () async {
    await service.savePackage(
      version: '0.1.1.1',
      fileName: 'a.zip',
      remark: 'old',
      createdAt: DateTime(2026, 1, 1),
    );
    final entity = repository.findByVersion('0.1.1.1')!;
    final originalCreatedAt = entity.createdAt;

    service.updatePackage(entity: entity, version: '0.2.2.2', remark: 'new');

    expect(repository.count(), 1);
    expect(repository.findByVersion('0.1.1.1'), isNull);
    final updated = repository.findByVersion('0.2.2.2')!;
    expect(updated.fileName, 'a.zip');
    expect(updated.remark, 'new');
    expect(updated.createdAt, originalCreatedAt);
  });

  test('deletePackage removes db row and zip plus extracted folder', () async {
    final fileName = await service.uploadZip(
      Uint8List.fromList([0x50, 0x4B, 0x05, 0x06, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      now: DateTime(2026, 9, 19, 12, 34, 56),
    );
    await service.savePackage(
      version: '0.1.1.1',
      fileName: fileName,
      createdAt: DateTime(2026, 9, 19, 12, 34, 56),
    );
    final entity = repository.findByVersion('0.1.1.1')!;

    await service.deletePackage(entity);

    expect(repository.count(), 0);
    expect(
      File(p.join(tempDir.path, 'install', fileName)).existsSync(),
      isFalse,
    );
    expect(
      Directory(p.join(tempDir.path, 'install', 'install_20260919_123456'))
          .existsSync(),
      isFalse,
    );
  });
}
