import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/update_step_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester,
    UpdateStepController controller, {
    VoidCallback? onStart,
    VoidCallback? onPause,
    VoidCallback? onCancel,
    VoidCallback? onClose,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateStepDialog(
            controller: controller,
            onStart: onStart,
            onPause: onPause,
            onCancel: onCancel,
            onClose: onClose,
          ),
        ),
      ),
    );
  }

  bool buttonEnabled(WidgetTester tester, String label) {
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, label),
    );
    return button.onPressed != null;
  }

  testWidgets('renders header and 7 step labels', (tester) async {
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'install_20260919_123456.zip',
    );

    await pumpDialog(
      tester,
      controller,
      onStart: () {},
      onPause: () {},
      onCancel: () {},
      onClose: () {},
    );

    expect(find.text('更新到设备'), findsOneWidget);
    expect(find.text('v0.1.1.1'), findsOneWidget);
    expect(find.text('install_20260919_123456.zip'), findsOneWidget);
    for (final label in UpdateStepController.stepLabels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('renders device table columns and rows', (tester) async {
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    controller.addDevice(
      UpdateDevice(ip: '192.168.1.10', type: 'CCU')
        ..currentVersion = '0.0.0.1'
        ..newVersion = '0.1.1.1'
        ..status = '认证成功'
        ..progress = 0.5
        ..result = '--',
    );

    await pumpDialog(tester, controller);

    expect(find.text('IP 地址'), findsOneWidget);
    expect(find.text('类型'), findsOneWidget);
    expect(find.text('当前版本'), findsOneWidget);
    expect(find.text('新版本'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('进度'), findsOneWidget);
    expect(find.text('结果'), findsOneWidget);
    expect(find.text('192.168.1.10'), findsOneWidget);
    expect(find.text('CCU'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('step status shows success and failed icons', (tester) async {
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );
    controller.setStepStatus(1, StepStatus.success);
    controller.setStepStatus(2, StepStatus.failed);

    await pumpDialog(tester, controller);

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('button state machine follows phase', (tester) async {
    final controller = UpdateStepController(
      version: '0.1.1.1',
      fileName: 'a.zip',
    );

    // idle
    await pumpDialog(
      tester,
      controller,
      onStart: () {},
      onPause: () {},
      onCancel: () {},
      onClose: () {},
    );
    expect(buttonEnabled(tester, '开始'), isTrue);
    expect(buttonEnabled(tester, '暂停'), isFalse);
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '关闭'), isTrue);

    // running
    controller.setPhase(UpdatePhase.running);
    await tester.pump();
    expect(buttonEnabled(tester, '开始'), isFalse);
    expect(buttonEnabled(tester, '暂停'), isTrue);
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '关闭'), isFalse);

    // paused
    controller.setPhase(UpdatePhase.paused);
    await tester.pump();
    expect(buttonEnabled(tester, '继续'), isTrue);
    expect(buttonEnabled(tester, '暂停'), isFalse);
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '关闭'), isTrue);

    // finished
    controller.setPhase(UpdatePhase.finished);
    await tester.pump();
    expect(buttonEnabled(tester, '开始'), isFalse);
    expect(buttonEnabled(tester, '暂停'), isFalse);
    expect(buttonEnabled(tester, '取消'), isFalse);
    expect(buttonEnabled(tester, '关闭'), isTrue);
  });
}
