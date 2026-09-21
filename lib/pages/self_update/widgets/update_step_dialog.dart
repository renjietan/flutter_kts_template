import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';

/// 更新到设备的步骤弹窗。
///
/// 横向 7 步步骤条 + 设备明细表 + 底部按钮状态机。
class UpdateStepDialog extends StatefulWidget {
  const UpdateStepDialog({
    super.key,
    required this.controller,
    this.onStart,
    this.onPause,
    this.onCancel,
    this.onClose,
  });

  final UpdateStepController controller;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;

  @override
  State<UpdateStepDialog> createState() => _UpdateStepDialogState();
}

class _UpdateStepDialogState extends State<UpdateStepDialog> {
  static const Color _accent = Color(0xFF00A2E9);
  static const Color _success = Color(0xFF2ECC71);
  static const Color _danger = Color(0xFFF15B64);
  static const Color _dim = Color(0xFF8A94A6);

  static const List<String> _descriptions = [
    '正在扫描网络中的 CPDC 设备…',
    '正在对设备进行认证…',
    '正在比对设备当前版本与目标版本…',
    '正在向认证成功的设备分发安装包…',
    '设备正在校验安装包完整性…',
    '设备正在替换程序并写入配置…',
    '等待设备回传更新结果…',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: _buildHeader(controller),
      content: SizedBox(
        width: 860,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepper(controller),
            const SizedBox(height: 16),
            Text(
              _descriptions[controller.activeStep],
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: controller.totalProgress,
              backgroundColor: const Color(0xFF353A41),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
            const SizedBox(height: 8),
            _buildTable(controller),
          ],
        ),
      ),
      actions: _buildActions(controller),
    );
  }

  Widget _buildHeader(UpdateStepController controller) {
    return Row(
      children: [
        const Text(
          '更新到设备',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(width: 16),
        Text(
          'v${controller.version}',
          style: const TextStyle(color: _accent, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            controller.fileName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(UpdateStepController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < controller.steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Container(
                  height: 2,
                  color: _connectorColor(controller, i),
                ),
              ),
            ),
          _buildStepItem(controller, i),
        ],
      ],
    );
  }

  Color _connectorColor(UpdateStepController controller, int index) {
    final terminated = controller.terminatedStep;
    if (terminated != null && index <= terminated) {
      return _danger;
    }
    if (index <= controller.activeStep) {
      return _accent;
    }
    return const Color(0xFF353A41);
  }

  Widget _buildStepItem(UpdateStepController controller, int index) {
    final status = controller.steps[index].status;
    final terminated = controller.terminatedStep == index;
    final active = index == controller.activeStep;

    Color circleColor;
    Widget circleContent;
    if (terminated || status == StepStatus.failed) {
      circleColor = _danger;
      circleContent = const Icon(Icons.close, size: 16, color: Colors.white);
    } else if (status == StepStatus.success) {
      circleColor = _success;
      circleContent = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (active || status == StepStatus.running) {
      circleColor = _accent;
      circleContent = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      circleColor = Colors.transparent;
      circleContent = Text(
        '${index + 1}',
        style: const TextStyle(color: _dim, fontSize: 12),
      );
    }

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(color: _dim, width: 1),
            ),
            alignment: Alignment.center,
            child: circleContent,
          ),
          const SizedBox(height: 6),
          Text(
            controller.steps[index].label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: terminated || status == StepStatus.failed
                  ? _danger
                  : active
                  ? Colors.white
                  : _dim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(UpdateStepController controller) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('IP 地址')),
              DataColumn(label: Text('类型')),
              DataColumn(label: Text('当前版本')),
              DataColumn(label: Text('新版本')),
              DataColumn(label: Text('状态')),
              DataColumn(label: Text('进度')),
              DataColumn(label: Text('结果')),
            ],
            rows: [
              for (final device in controller.devices)
                DataRow(
                  cells: [
                    DataCell(Text(device.ip)),
                    DataCell(Text(device.type)),
                    DataCell(Text(device.currentVersion.isEmpty ? '--' : device.currentVersion)),
                    DataCell(Text(device.newVersion.isEmpty ? '--' : device.newVersion)),
                    DataCell(Text(device.status.isEmpty ? '--' : device.status)),
                    DataCell(Text('${(device.progress * 100).round()}%')),
                    DataCell(Text(device.result.isEmpty ? '--' : device.result)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(UpdateStepController controller) {
    final phase = controller.phase;
    final startEnabled = phase == UpdatePhase.idle || phase == UpdatePhase.paused;
    final pauseEnabled = phase == UpdatePhase.running;
    final cancelEnabled = phase != UpdatePhase.finished;
    final closeEnabled = phase != UpdatePhase.running;

    return [
      if (controller.summary.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            controller.summary,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      TextButton(
        onPressed: startEnabled ? widget.onStart : null,
        child: Text(phase == UpdatePhase.paused ? '继续' : '开始'),
      ),
      TextButton(
        onPressed: pauseEnabled ? widget.onPause : null,
        child: const Text('暂停'),
      ),
      TextButton(
        onPressed: cancelEnabled ? widget.onCancel : null,
        child: const Text('取消'),
      ),
      TextButton(
        onPressed: closeEnabled ? widget.onClose : null,
        child: const Text('关闭'),
      ),
    ];
  }
}
