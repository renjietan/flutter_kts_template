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
    VoidCallback? onResume,
    Future<void> Function()? onReAuth,
    Future<void> Function()? onReVersion,
    Future<void> Function()? onCancel,
    Future<void> Function()? onClose,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateStepDialog(
            controller: controller,
            onStart: onStart,
            onPause: onPause,
            onResume: onResume,
            onReAuth: onReAuth,
            onReVersion: onReVersion,
            onCancel: onCancel,
            onClose: onClose,
          ),
        ),
      ),
    );
  }

  bool buttonEnabled(WidgetTester tester, String label) {
    final finder = find.widgetWithText(TextButton, label);
    if (finder.evaluate().isEmpty) {
      return false;
    }
    return tester.widget<TextButton>(finder).onPressed != null;
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
      onCancel: () async {},
      onClose: () async {},
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
    expect(find.textContaining('50%'), findsOneWidget);
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

    Future<void> pump() => pumpDialog(
          tester,
          controller,
          onStart: () {},
          onPause: () {},
          onResume: () {},
          onReAuth: () async {},
          onReVersion: () async {},
          onCancel: () async {},
          onClose: () async {},
        );

    // idle：发现/认证/版本校验阶段无按钮
    await pump();
    expect(buttonEnabled(tester, '开始'), isFalse);
    expect(buttonEnabled(tester, '暂停'), isFalse);
    expect(buttonEnabled(tester, '取消'), isFalse);
    expect(buttonEnabled(tester, '关闭'), isFalse);

    // 传输：待开始
    controller.setActiveStep(3);
    controller.setPhase(UpdatePhase.running);
    controller.setTransferStage(TransferStage.notStarted);
    await tester.pump();
    expect(buttonEnabled(tester, '开始'), isTrue);
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '暂停'), isFalse);
    expect(buttonEnabled(tester, '关闭'), isFalse);

    // 传输：发送中
    controller.setTransferStage(TransferStage.sending);
    await tester.pump();
    expect(buttonEnabled(tester, '暂停'), isTrue);
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '开始'), isFalse);

    // 传输：暂停
    controller.setTransferStage(TransferStage.paused);
    await tester.pump();
    expect(buttonEnabled(tester, '继续'), isTrue);
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '暂停'), isFalse);

    // 认证失败：取消 + 重新认证
    controller.setActiveStep(1);
    controller.setPhase(UpdatePhase.authFailed);
    await tester.pump();
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '重新认证'), isTrue);
    expect(buttonEnabled(tester, '关闭'), isFalse);

    // 版本校验失败：取消 + 重新版本校验
    controller.setActiveStep(2);
    controller.setPhase(UpdatePhase.versionFailed);
    await tester.pump();
    expect(buttonEnabled(tester, '取消'), isTrue);
    expect(buttonEnabled(tester, '重新版本校验'), isTrue);
    expect(buttonEnabled(tester, '重新认证'), isFalse);
    expect(buttonEnabled(tester, '关闭'), isFalse);

    // 完成：关闭
    controller.setPhase(UpdatePhase.finished);
    await tester.pump();
    expect(buttonEnabled(tester, '关闭'), isTrue);
    expect(buttonEnabled(tester, '取消'), isFalse);
    expect(buttonEnabled(tester, '重新认证'), isFalse);
    expect(buttonEnabled(tester, '重新版本校验'), isFalse);
  });
}
