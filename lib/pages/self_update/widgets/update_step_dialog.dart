// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/utils/arabic_digits.dart';

/// 更新到设备的步骤弹窗。
///
/// 横向 7 步步骤条 + 设备明细表 + 底部按钮状态机。
class UpdateStepDialog extends StatefulWidget {
  const UpdateStepDialog({
    super.key,
    required this.controller,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onReAuth,
    this.onReVersion,
    this.onReValid,
    this.onReWrite,
    this.onCancel,
    this.onClose,
  });

  final UpdateStepController controller;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final Future<void> Function()? onReAuth;
  final Future<void> Function()? onReVersion;
  final Future<void> Function()? onReValid;
  final Future<void> Function()? onReWrite;
  final Future<void> Function()? onCancel;
  final Future<void> Function()? onClose;

  @override
  State<UpdateStepDialog> createState() => _UpdateStepDialogState();
}

class _UpdateStepDialogState extends State<UpdateStepDialog> {
  static const Color _accent = Color(0xFF00A2E9);
  static const Color _success = Color(0xFF2ECC71);
  static const Color _danger = Color(0xFFF15B64);
  static const Color _dim = Color(0xFF8A94A6);
  bool _closing = false;
  bool _reAuthing = false;
  bool _reVersioning = false;
  bool _reValiding = false;
  bool _reWriting = false;

  static List<String> get _descriptions => [
    t.selfUpdate.descDiscovery,
    t.selfUpdate.descAuth,
    t.selfUpdate.descVersion,
    t.selfUpdate.descTransfer,
    t.selfUpdate.descValidation,
    t.selfUpdate.descWrite,
    t.selfUpdate.descReceipt,
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

  Future<void> _handleCancel() async {
    if (_closing) {
      return;
    }
    setState(() => _closing = true);
    await widget.onCancel?.call();
    if (!mounted) {
      return;
    }
    setState(() => _closing = false);
    Navigator.of(context).pop();
  }

  Future<void> _handleClose() async {
    if (_closing) {
      return;
    }
    setState(() => _closing = true);
    await widget.onClose?.call();
    if (!mounted) {
      return;
    }
    setState(() => _closing = false);
    Navigator.of(context).pop();
  }

  Future<void> _handleReAuth() async {
    if (_closing || _reAuthing) {
      return;
    }
    setState(() => _reAuthing = true);
    await widget.onReAuth?.call();
    if (!mounted) {
      return;
    }
    setState(() => _reAuthing = false);
  }

  Future<void> _handleReVersion() async {
    if (_closing || _reVersioning) {
      return;
    }
    setState(() => _reVersioning = true);
    await widget.onReVersion?.call();
    if (!mounted) {
      return;
    }
    setState(() => _reVersioning = false);
  }

  Future<void> _handleReValid() async {
    if (_closing || _reValiding) {
      return;
    }
    setState(() => _reValiding = true);
    await widget.onReValid?.call();
    if (!mounted) {
      return;
    }
    setState(() => _reValiding = false);
  }

  Future<void> _handleReWrite() async {
    if (_closing || _reWriting) {
      return;
    }
    setState(() => _reWriting = true);
    await widget.onReWrite?.call();
    if (!mounted) {
      return;
    }
    setState(() => _reWriting = false);
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(1)}MB';
    }
    if (bytes >= 1 << 10) {
      return '${(bytes / (1 << 10)).toStringAsFixed(1)}KB';
    }
    return '${bytes}B';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final showPause =
        controller.activeStep == 3 &&
        controller.phase == UpdatePhase.running &&
        controller.transferStage == TransferStage.sending;
    final showResume =
        controller.activeStep == 3 &&
        controller.phase == UpdatePhase.running &&
        controller.transferStage == TransferStage.paused;
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
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: controller.totalProgress,
                    backgroundColor: const Color(0xFF353A41),
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
                if (showPause || showResume) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: showPause
                        ? widget.onPause
                        : (showResume ? widget.onResume : null),
                    child: Text(
                      showPause ? t.selfUpdate.pause : t.selfUpdate.resume,
                    ),
                  ),
                ],
              ],
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
        Text(
          t.selfUpdate.updateToDevice,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(width: 16),
        Text(
          localizeDigits(context, 'v${controller.version}'),
          style: const TextStyle(color: _accent, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            localizeDigits(context, controller.fileName),
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
        localizeDigits(context, '${index + 1}'),
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
            columns: [
              DataColumn(label: Text(t.selfUpdate.colIp)),
              DataColumn(label: Text(t.selfUpdate.colType)),
              DataColumn(label: Text(t.selfUpdate.colCurrentVersion)),
              DataColumn(label: Text(t.selfUpdate.colNewVersion)),
              DataColumn(label: Text(t.selfUpdate.colStatus)),
              DataColumn(label: Text(t.selfUpdate.colProgress)),
              DataColumn(label: Text(t.selfUpdate.colResult)),
            ],
            rows: [
              for (final device in controller.devices)
                DataRow(
                  cells: [
                    DataCell(Text(device.ip)),
                    DataCell(Text(device.type)),
                    DataCell(
                      Text(
                        localizeDigits(
                          context,
                          device.currentVersion.isEmpty
                              ? '--'
                              : device.currentVersion,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        localizeDigits(
                          context,
                          device.newVersion.isEmpty ? '--' : device.newVersion,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(device.status.isEmpty ? '--' : device.status),
                    ),
                    DataCell(
                      Text(
                        localizeDigits(
                          context,
                          '${(device.progress * 100).round()}% · ${_formatBytes(device.transferredBytes)}/${_formatBytes(device.totalBytes)}',
                        ),
                      ),
                    ),
                    DataCell(
                      device.result.isEmpty
                          ? const Text('--')
                          : InkWell(
                              onTap: () => _showDeviceDetail(device),
                              child: Text(
                                localizeDigits(context, device.result),
                                style: const TextStyle(
                                  color: _accent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeviceDetail(UpdateDevice device) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF20262D),
          title: Text(
            '${device.type} - ${device.ip}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Text(
            localizeDigits(
              context,
              device.detail.isNotEmpty ? device.detail : device.result,
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.selfUpdate.close),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildActions(UpdateStepController controller) {
    final phase = controller.phase;
    final inAuth = controller.activeStep == 1 && phase == UpdatePhase.running;
    final inVersion =
        controller.activeStep == 2 && phase == UpdatePhase.running;
    final inTransfer =
        controller.activeStep == 3 && phase == UpdatePhase.running;
    final inValid = controller.activeStep == 4 && phase == UpdatePhase.running;
    final showStart =
        inTransfer && controller.transferStage == TransferStage.notStarted;
    final showCancel =
        inAuth ||
        inVersion ||
        inTransfer ||
        inValid ||
        phase == UpdatePhase.authFailed ||
        phase == UpdatePhase.versionFailed ||
        phase == UpdatePhase.validFailed ||
        phase == UpdatePhase.writeFailed;
    final showReAuth = phase == UpdatePhase.authFailed;
    final showReVersion = phase == UpdatePhase.versionFailed;
    final showReValid = phase == UpdatePhase.validFailed;
    final showReWrite = phase == UpdatePhase.writeFailed;
    final showClose = phase == UpdatePhase.finished;

    return [
      if (controller.summary.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            localizeDigits(context, controller.summary),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      if (showStart)
        TextButton(onPressed: widget.onStart, child: Text(t.selfUpdate.start)),
      if (showCancel)
        TextButton(
          onPressed: _closing ? null : _handleCancel,
          child: _closing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  t.selfUpdate.cancel,
                  style: const TextStyle(color: Colors.white70),
                ),
        ),
      if (showReAuth)
        TextButton(
          onPressed: (_closing || _reAuthing) ? null : _handleReAuth,
          child: _reAuthing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.selfUpdate.reAuth),
        ),
      if (showReVersion)
        TextButton(
          onPressed: (_closing || _reVersioning) ? null : _handleReVersion,
          child: _reVersioning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.selfUpdate.reVersion),
        ),
      if (showReValid)
        TextButton(
          onPressed: (_closing || _reValiding) ? null : _handleReValid,
          child: _reValiding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.selfUpdate.revalidate),
        ),
      if (showReWrite)
        TextButton(
          onPressed: (_closing || _reWriting) ? null : _handleReWrite,
          child: _reWriting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.selfUpdate.rewrite),
        ),
      if (showClose)
        TextButton(
          onPressed: _closing ? null : _handleClose,
          child: _closing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.selfUpdate.close),
        ),
    ];
  }
}
