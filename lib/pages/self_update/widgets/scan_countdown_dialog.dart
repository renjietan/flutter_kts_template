import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/selfUpdate/scan/scan_controller.dart';

/// 发现阶段的扫描倒计时弹窗。
///
/// 圆形进度 + 三行居中文字（扫描中 / 已扫描 N 台 / 剩余秒）+ 取消按钮。
class ScanCountdownDialog extends StatefulWidget {
  const ScanCountdownDialog({
    super.key,
    required this.controller,
    this.onCancel,
    this.onComplete,
  });

  final ScanController controller;
  final VoidCallback? onCancel;
  final void Function(int deviceCount)? onComplete;

  @override
  State<ScanCountdownDialog> createState() => _ScanCountdownDialogState();
}

class _ScanCountdownDialogState extends State<ScanCountdownDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.start();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (widget.controller.state == ScanState.done) {
      widget.onComplete?.call(widget.controller.deviceCount);
    }
  }

  Future<void> _cancel() async {
    await widget.controller.cancel();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: const Text(
        '扫描设备',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      content: SizedBox(
        width: 280,
        height: 260,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: controller.progress,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFF353A41),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00A2E9),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '扫描中....',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '已扫描到 ${controller.deviceCount} 个设备',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '剩余 ${controller.remainingSeconds} 秒',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: controller.state == ScanState.scanning ? _cancel : null,
          child: const Text('取消'),
        ),
      ],
    );
  }
}
