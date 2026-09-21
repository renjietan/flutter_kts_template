import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_repository.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/self_update_service.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_kts_template/pages/self_update/self_update.pager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late Store store;
  late SelfUpdateService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('self_update_pager_test');
    store = await openStore(directory: tempDir.path);
    service = SelfUpdateService(
      repository: InstallPackageRepository(
        store.box<InstallPackageEntity>(),
      ),
      storage: InstallPackageStorage(
        installDirectory: Directory(p.join(tempDir.path, 'install')),
      ),
    );
  });

  tearDown(() {
    store.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> pumpPager(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelfUpdatePager(
            service: service,
            pickZipFile: () async => Uint8List(0),
          ),
        ),
      ),
    );
  }

  testWidgets('renders seeded packages', (tester) async {
    await tester.runAsync(
      () => service.savePackage(
        version: '0.1.1.1',
        fileName: 'install_20260919_123456.zip',
        remark: 'hello',
        createdAt: DateTime(2026, 9, 19, 12, 34, 56),
      ),
    );

    await pumpPager(tester);

    expect(find.text('0.1.1.1'), findsOneWidget);
    expect(find.text('install_20260919_123456.zip'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('tapping file upload opens the dialog', (tester) async {
    await pumpPager(tester);

    await tester.tap(find.text('文件上传'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('上传安装包'), findsOneWidget);
    expect(find.textContaining('版本号'), findsOneWidget);
    expect(find.text('备注（选填）'), findsOneWidget);
  });
}
