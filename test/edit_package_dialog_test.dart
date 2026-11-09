import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/edit_package_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    void Function(String version, String? remark)? onConfirm,
    bool usePage = false,
  }) async {
    final entity = InstallPackageEntity(
      version: '0.1.1.1',
      fileName: 'install_20260919_123456.zip',
      remark: 'old',
      createdAt: DateTime(2026, 9, 19, 12, 34, 56),
    );
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
                    final dialog = EditPackageDialog(
                      entity: entity,
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

    await tester.enterText(
      find.byKey(const ValueKey('edit_version_field')),
      '',
    );
    await tester.tap(find.text('确定'));
    await tester.pump();

    expect(find.text('请输入版本号'), findsOneWidget);
    expect(find.text('编辑安装包'), findsOneWidget);
  });

  testWidgets('valid confirm closes dialog and triggers onConfirm', (
    tester,
  ) async {
    String? confirmedVersion;
    String? confirmedRemark;
    await pumpDialog(
      tester,
      onConfirm: (version, remark) {
        confirmedVersion = version;
        confirmedRemark = remark;
      },
    );

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

    expect(confirmedVersion, '0.2.2.2');
    expect(confirmedRemark, 'edited');
    expect(find.text('编辑安装包'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('valid confirm closes page and triggers onConfirm', (
    tester,
  ) async {
    String? confirmedVersion;
    await pumpDialog(
      tester,
      usePage: true,
      onConfirm: (version, remark) {
        confirmedVersion = version;
      },
    );

    await tester.enterText(
      find.byKey(const ValueKey('edit_version_field')),
      '0.2.2.2',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(confirmedVersion, '0.2.2.2');
    expect(find.text('编辑安装包'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
