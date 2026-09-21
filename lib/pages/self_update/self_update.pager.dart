import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/scan/scan_controller.dart';
import 'package:flutter_kts_template/core/selfUpdate/self_update_service.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/udp_update_transport.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_flow_coordinator.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/transfer_coordinator.dart';
import 'package:flutter_kts_template/core/selfUpdate/update/update_step_controller.dart';
import 'package:flutter_kts_template/pages/self_update/self_update.page.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/upload_package_dialog.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/scan_countdown_dialog.dart';
import 'package:flutter_kts_template/pages/self_update/widgets/update_step_dialog.dart';
import 'package:path/path.dart' as p;

/// 自更新上传页面的编排层。
///
/// 负责把文件选择（[pickZipFile]）、上传服务（[SelfUpdateService]）、
/// 上传弹窗与 [SelfUpdatePage] 串起来；文件选择以函数注入，便于测试替换。
class SelfUpdatePager extends StatefulWidget {
  const SelfUpdatePager({
    super.key,
    required this.service,
    required this.pickZipFile,
  });

  final SelfUpdateService service;

  /// 选择 ZIP 并返回其字节；取消返回 null。
  final Future<Uint8List?> Function() pickZipFile;

  @override
  State<SelfUpdatePager> createState() => _SelfUpdatePagerState();
}

class _SelfUpdatePagerState extends State<SelfUpdatePager> {
  int _reloadVersion = 0;
  bool _transferRunning = false;

  Future<void> _handleUpload() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return UploadPackageDialog(
          onPickFile: () async {
            final bytes = await widget.pickZipFile();
            if (bytes == null) {
              return null;
            }
            return widget.service.uploadZip(bytes);
          },
          onConfirm: (version, remark, fileName) async {
            await widget.service.savePackage(
              version: version,
              remark: remark,
              fileName: fileName,
            );
            if (!mounted) {
              return;
            }
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            _reload();
          },
        );
      },
    );
  }

  Future<void> _handleDelete(InstallPackageEntity entity) async {
    await widget.service.deletePackage(entity);
    _reload();
  }

  void _handleEdit(
    InstallPackageEntity entity,
    String version,
    String? remark,
  ) {
    widget.service.updatePackage(
      entity: entity,
      version: version,
      remark: remark,
    );
    _reload();
  }

  Future<void> _handleUpdate(InstallPackageEntity entity) async {
    // 安装包文件已不存在时，提示是否立刻删除数据。
    final exists = await widget.service.packageExists(entity.fileName);
    if (!exists) {
      final shouldDelete = await _confirmDeleteMissing();
      if (shouldDelete == true && mounted) {
        await widget.service.deletePackage(entity);
        _reload();
      }
      return;
    }

    await _runUpdateFlow(entity);
  }

  Future<bool?> _confirmDeleteMissing() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('安装包不存在，是否立刻删除数据'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runUpdateFlow(InstallPackageEntity entity) async {
    final transport = UdpUpdateTransport();
    await transport.init();
    final session = UpdateSession(transport: transport);

    try {
      // 发现阶段：扫描倒计时弹窗。
      final scanController = ScanController(transport: transport);
      final scanned = await _scan(scanController);
      if (scanned == null) {
        return;
      }
      if (scanned == 0) {
        await _showNoDevices();
        return;
      }

      // 认证/版本校验/传输/校验/写入/回执：步骤弹窗。
      final baseName = p.basenameWithoutExtension(entity.fileName);
      final stepController = UpdateStepController(
        version: entity.version,
        fileName: entity.fileName,
      );
      stepController.setStepStatus(0, StepStatus.success);

      final flow = UpdateFlowCoordinator(
        session: session,
        controller: stepController,
        storage: widget.service.storage,
        baseName: baseName,
        targetVersion: entity.version,
      );
      final transfer = TransferCoordinator(
        session: session,
        controller: stepController,
        storage: widget.service.storage,
        baseName: baseName,
      );

      await _runStepDialog(stepController, flow, transfer, session);
    } finally {
      await session.reset();
    }
  }

  Future<int?> _scan(ScanController scanController) {
    return showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ScanCountdownDialog(
          controller: scanController,
          onCancel: () => Navigator.of(dialogContext).pop(null),
          onComplete: (count) => Navigator.of(dialogContext).pop(count),
        );
      },
    );
  }

  Future<void> _showNoDevices() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('未扫描到设备'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runStepDialog(
    UpdateStepController stepController,
    UpdateFlowCoordinator flow,
    TransferCoordinator transfer,
    UpdateSession session,
  ) async {
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return UpdateStepDialog(
          controller: stepController,
          onStart: () => _runTransfer(transfer, stepController),
          onPause: () {},
          onCancel: () async {
            await session.reset();
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
          onClose: () async {
            await session.reset();
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );

    // 弹窗首帧渲染后，立刻进入认证 + 版本校验。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      stepController.setPhase(UpdatePhase.running);
      flow.runAuthAndVersion();
    });

    await dialogFuture;
  }

  Future<void> _runTransfer(
    TransferCoordinator transfer,
    UpdateStepController stepController,
  ) async {
    if (_transferRunning) {
      return;
    }
    _transferRunning = true;
    stepController.setPhase(UpdatePhase.running);
    try {
      final devices = stepController.devices
          .where((d) => d.status == '需更新')
          .toList();
      if (devices.isEmpty) {
        stepController.setSummary('没有需要更新的设备');
        stepController.setPhase(UpdatePhase.finished);
        return;
      }
      final ok = await transfer.run(devices);
      if (ok) {
        await transfer.runReceipt(devices);
      }
    } finally {
      _transferRunning = false;
    }
  }

  void _reload() {
    setState(() {
      _reloadVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SelfUpdatePage(
      key: ValueKey(_reloadVersion),
      repository: widget.service.repository,
      onUpload: _handleUpload,
      onDelete: _handleDelete,
      onUpdate: _handleUpdate,
      onEdit: _handleEdit,
    );
  }
}
