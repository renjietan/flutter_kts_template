import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_repository.dart';
import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:flutter_kts_template/pages/self_update/self_update.page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late Store store;
  late InstallPackageRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('self_update_page_test');
    store = await openStore(directory: tempDir.path);
    repository = InstallPackageRepository(store.box<InstallPackageEntity>());
  });

  tearDown(() {
    store.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    VoidCallback? onUpload,
    void Function(InstallPackageEntity)? onDelete,
    void Function(InstallPackageEntity)? onUpdate,
    void Function(InstallPackageEntity, String, String?)? onEdit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelfUpdatePage(
            repository: repository,
            onUpload: onUpload,
            onDelete: onDelete,
            onUpdate: onUpdate,
            onEdit: onEdit,
          ),
        ),
      ),
    );
  }

  void seed(List<InstallPackageEntity> entities) {
    for (final entity in entities) {
      repository.save(entity);
    }
  }

  testWidgets('shows empty state when there is no data', (tester) async {
    await pumpPage(tester);
    expect(find.text('暂无数据'), findsOneWidget);
  });

  testWidgets('renders rows sorted by createdAt descending', (tester) async {
    seed([
      InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'a.zip',
        createdAt: DateTime(2026, 1, 1),
      ),
      InstallPackageEntity(
        version: '0.1.1.2',
        fileName: 'b.zip',
        createdAt: DateTime(2026, 1, 3),
      ),
      InstallPackageEntity(
        version: '0.1.1.3',
        fileName: 'c.zip',
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);

    await pumpPage(tester);

    final yNewest = tester.getTopLeft(find.text('0.1.1.2')).dy;
    final yMiddle = tester.getTopLeft(find.text('0.1.1.3')).dy;
    final yOldest = tester.getTopLeft(find.text('0.1.1.1')).dy;
    expect(yNewest, lessThan(yMiddle));
    expect(yMiddle, lessThan(yOldest));
  });

  testWidgets('search filters by version, fileName, or remark', (tester) async {
    seed([
      InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'alpha.zip',
        remark: 'hello',
        createdAt: DateTime(2026, 1, 1),
      ),
      InstallPackageEntity(
        version: '0.2.2.2',
        fileName: 'beta.zip',
        remark: 'world',
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);

    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pump();

    expect(find.text('beta.zip'), findsOneWidget);
    expect(find.text('alpha.zip'), findsNothing);
  });

  testWidgets('row edit, update, and delete buttons work', (tester) async {
    seed([
      InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'a.zip',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    InstallPackageEntity? deleted;
    InstallPackageEntity? updated;
    InstallPackageEntity? edited;
    String? editedVersion;
    String? editedRemark;
    await pumpPage(
      tester,
      onDelete: (e) => deleted = e,
      onUpdate: (e) => updated = e,
      onEdit: (e, version, remark) {
        edited = e;
        editedVersion = version;
        editedRemark = remark;
      },
    );

    await tester.ensureVisible(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('edit_version_field')),
      '0.2.2.2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit_remark_field')),
      'edited',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(edited?.version, '0.1.1.1');
    expect(editedVersion, '0.2.2.2');
    expect(editedRemark, 'edited');

    await tester.ensureVisible(find.byIcon(Icons.system_update));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.system_update));
    await tester.pumpAndSettle();
    expect(updated?.version, '0.1.1.1');

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('删除提示'), findsOneWidget);
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(deleted?.version, '0.1.1.1');
  });

  testWidgets('delete confirmation cancel does not delete', (tester) async {
    seed([
      InstallPackageEntity(
        version: '0.1.1.1',
        fileName: 'a.zip',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    InstallPackageEntity? deleted;
    await pumpPage(tester, onDelete: (e) => deleted = e);

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(deleted, isNull);
  });

  testWidgets('pagination splits rows into pages', (tester) async {
    seed([
      for (var i = 0; i < 25; i++)
        InstallPackageEntity(
          version: '0.0.0.$i',
          fileName: 'f$i.zip',
          createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
        ),
    ]);

    await pumpPage(tester);

    expect(find.textContaining('共 25 条'), findsOneWidget);
    // 第 1 页显示最新（i=24），不显示最旧（i=0）。
    expect(find.text('f24.zip'), findsOneWidget);
    expect(find.text('f0.zip'), findsNothing);
  });
}
