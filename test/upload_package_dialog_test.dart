import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/upload_package_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    Future<String?> Function()? onPickFile,
    void Function(String version, String? remark, String fileName)? onConfirm,
    bool usePage = false,
  }) async {
    LocaleSettings.setLocaleSync(AppLocale.zh);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    final dialog = UploadPackageDialog(
                      onPickFile: onPickFile,
                      onConfirm: onConfirm,
                      usePage: usePage,
                    );
                    if (usePage) {
                      Navigator.of(
                        context,
                      ).push<void>(MaterialPageRoute(builder: (_) => dialog));
                    } else {
                      showDialog<void>(
                        context: context,
                        builder: (_) => dialog,
                      );
                    }
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('version is required', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('确定'));
    await tester.pump();

    expect(find.text('请输入版本号'), findsOneWidget);
  });

  testWidgets('version must be four dot-separated numeric parts', (
    tester,
  ) async {
    await pumpDialog(tester);
    final versionField = find.byKey(const ValueKey('version_field'));

    await tester.enterText(versionField, '1.2.3');
    await tester.tap(find.text('确定'));
    await tester.pump();
    expect(find.text('格式应为 0.1.1.1'), findsOneWidget);

    await tester.enterText(versionField, '1.2.3.4.5');
    await tester.tap(find.text('确定'));
    await tester.pump();
    expect(find.text('格式应为 0.1.1.1'), findsOneWidget);

    await tester.enterText(versionField, '1.a.3.4');
    await tester.tap(find.text('确定'));
    await tester.pump();
    expect(find.text('格式应为 0.1.1.1'), findsOneWidget);
  });

  testWidgets('valid version and file trigger onConfirm', (tester) async {
    String? confirmedVersion;
    String? confirmedRemark;
    String? confirmedFileName;
    await pumpDialog(
      tester,
      onPickFile: () async => 'install_20260919_123456.zip',
      onConfirm: (version, remark, fileName) {
        confirmedVersion = version;
        confirmedRemark = remark;
        confirmedFileName = fileName;
      },
    );

    await tester.tap(find.text('上传'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('version_field')),
      '0.1.1.1',
    );
    await tester.enterText(find.byKey(const ValueKey('remark_field')), 'hello');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(confirmedVersion, '0.1.1.1');
    expect(confirmedRemark, 'hello');
    expect(confirmedFileName, 'install_20260919_123456.zip');
    expect(find.text('上传安装包'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('confirm in page mode closes the page and triggers onConfirm', (
    tester,
  ) async {
    String? confirmedVersion;
    await pumpDialog(
      tester,
      usePage: true,
      onPickFile: () async => 'install_20260919_123456.zip',
      onConfirm: (version, remark, fileName) {
        confirmedVersion = version;
      },
    );

    await tester.tap(find.text('上传'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('version_field')),
      '0.1.1.1',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(confirmedVersion, '0.1.1.1');
    expect(find.text('上传安装包'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('upload button shows loading during upload and clears after', (
    tester,
  ) async {
    final completer = Completer<String?>();
    await pumpDialog(tester, onPickFile: () => completer.future);

    await tester.tap(find.text('上传'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete('install_20260919_123456.zip');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('install_20260919_123456.zip'), findsOneWidget);
  });

  testWidgets('remark is limited to 150 characters', (tester) async {
    await pumpDialog(tester);
    final remarkField = find.byKey(const ValueKey('remark_field'));

    final longText = 'a' * 200;
    await tester.enterText(remarkField, longText);
    await tester.pump();

    final editableText = tester.widget<EditableText>(
      find.descendant(of: remarkField, matching: find.byType(EditableText)),
    );
    expect(editableText.controller.text.length, 150);
  });

  testWidgets('file field shows inline error when no package selected', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.enterText(
      find.byKey(const ValueKey('version_field')),
      '0.1.1.1',
    );
    await tester.tap(find.text('确定'));
    await tester.pump();

    expect(find.text('请先上传安装包'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
