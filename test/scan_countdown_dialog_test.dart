import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/selfUpdate/scan/scan_controller.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/scan_countdown_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockTransport implements UpdateTransport {
  final sent = <Uint8List>[];
  final _controller = StreamController<Uint8List>.broadcast(sync: true);
  bool closed = false;

  @override
  Future<void> send(Uint8List data) async {
    sent.add(data);
  }

  @override
  Stream<Uint8List> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emit(String text) =>
      _controller.add(Uint8List.fromList(text.codeUnits));
}

void main() {
  testWidgets('shows initial countdown and counts devices', (tester) async {
    final transport = _MockTransport();
    final controller = ScanController(
      transport: transport,
      duration: const Duration(seconds: 10),
      tick: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScanCountdownDialog(controller: controller)),
      ),
    );
    await tester.pump();

    expect(find.text('扫描中....'), findsOneWidget);
    expect(find.text('已扫描到 0 个设备'), findsOneWidget);
    expect(find.text('剩余 10 秒'), findsOneWidget);
    expect(transport.sent.length, 1);

    transport.emit('Scan:success');
    await tester.pump();

    expect(find.text('已扫描到 1 个设备'), findsOneWidget);
    await controller.cancel();
  });

  testWidgets('remaining seconds decrements and completes after duration', (
    tester,
  ) async {
    final transport = _MockTransport();
    int? completedCount;
    final controller = ScanController(
      transport: transport,
      duration: const Duration(seconds: 10),
      tick: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanCountdownDialog(
            controller: controller,
            onComplete: (count) => completedCount = count,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('剩余 7 秒'), findsOneWidget);

    transport.emit('Scan:success');
    await tester.pump();
    expect(find.text('已扫描到 1 个设备'), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    expect(controller.state, ScanState.done);
    expect(completedCount, 1);
  });

  testWidgets('cancel closes transport and invokes onCancel', (tester) async {
    final transport = _MockTransport();
    var cancelled = false;
    final controller = ScanController(
      transport: transport,
      duration: const Duration(seconds: 10),
      tick: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanCountdownDialog(
            controller: controller,
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('取消'));
    await tester.pump();

    expect(cancelled, isTrue);
    expect(transport.closed, isTrue);
    expect(controller.state, ScanState.cancelled);
  });
}
