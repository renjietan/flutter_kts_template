import 'dart:io';

import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_repository.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstallPackageEntity JSON', () {
    test('round-trips with remark', () {
      final entity = InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'install_20260918_120000.zip',
        remark: 'hello',
        createdAt: DateTime(2026, 9, 18, 12, 0, 0),
      );

      final restored = InstallPackageEntity.fromJson(entity.toJson());

      expect(restored.version, '0.1.1.1');
      expect(restored.fileName, 'install_20260918_120000.zip');
      expect(restored.remark, 'hello');
      expect(restored.createdAt, DateTime(2026, 9, 18, 12, 0, 0));
    });

    test('round-trips with null remark', () {
      final entity = InstallPackageEntity(
        version: '0.1.1.2',
        fileName: 'install_20260918_130000.zip',
        createdAt: DateTime(2026, 9, 18, 13, 0, 0),
      );

      final restored = InstallPackageEntity.fromJson(entity.toJson());

      expect(restored.remark, isNull);
    });

    test('round-trips empty-string remark distinctly from null', () {
      final entity = InstallPackageEntity(
        version: '0.1.1.3',
        fileName: 'install_20260918_150000.zip',
        remark: '',
        createdAt: DateTime(2026, 9, 18, 15, 0, 0),
      );

      final restored = InstallPackageEntity.fromJson(entity.toJson());

      expect(restored.remark, isEmpty);
      expect(restored.remark, isNotNull);
    });
  });

  group('InstallPackageEntity ObjectBox', () {
    late Directory tempDir;
    late Store store;
    late InstallPackageRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('install_pkg_test');
      store = await openStore(directory: tempDir.path);
      repository = InstallPackageRepository(store.box<InstallPackageEntity>());
    });

    tearDown(() {
      store.close();
      tempDir.deleteSync(recursive: true);
    });

    test('put/get round-trips fields including nullable remark', () {
      final box = store.box<InstallPackageEntity>();

      final withRemark = InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'install_20260918_120000.zip',
        remark: 'hello',
        createdAt: DateTime(2026, 9, 18, 12, 0, 0),
      );
      final id1 = box.put(withRemark);
      final loaded1 = box.get(id1)!;
      expect(loaded1.version, '0.1.1.1');
      expect(loaded1.remark, 'hello');
      expect(loaded1.createdAt, DateTime(2026, 9, 18, 12, 0, 0));

      final withoutRemark = InstallPackageEntity(
        version: '0.1.1.2',
        fileName: 'install_20260918_130000.zip',
        createdAt: DateTime(2026, 9, 18, 13, 0, 0),
      );
      final id2 = box.put(withoutRemark);
      final loaded2 = box.get(id2)!;
      expect(loaded2.remark, isNull);
    });

    test('save overwrites on same version', () {
      final first = InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'install_20260918_120000.zip',
        remark: 'first',
        createdAt: DateTime(2026, 9, 18, 12, 0, 0),
      );
      repository.save(first);

      final second = InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'install_20260918_140000.zip',
        remark: 'second',
        createdAt: DateTime(2026, 9, 18, 14, 0, 0),
      );
      repository.save(second);

      expect(repository.count(), 1);
      final loaded = repository.findByVersion('0.1.1.1')!;
      expect(loaded.fileName, 'install_20260918_140000.zip');
      expect(loaded.remark, 'second');
    });

    test('getAll orders by createdAt descending', () {
      repository.save(
        InstallPackageEntity(
          version: '0.1.1.1',
          fileName: 'a.zip',
          createdAt: DateTime(2026, 9, 18, 10),
        ),
      );
      repository.save(
        InstallPackageEntity(
          version: '0.1.1.2',
          fileName: 'b.zip',
          createdAt: DateTime(2026, 9, 18, 12),
        ),
      );

      final all = repository.getAll();
      expect(all.first.version, '0.1.1.2');
      expect(all.last.version, '0.1.1.1');
    });

    test('getAll on empty box returns an empty list', () {
      expect(repository.getAll(), isEmpty);
      expect(repository.count(), 0);
    });
  });
}
