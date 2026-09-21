import 'package:flutter/material.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';

/// 编辑安装包信息弹窗。
///
/// 可编辑 version 与备注，文件名称只读展示。
class EditPackageDialog extends StatefulWidget {
  const EditPackageDialog({
    super.key,
    required this.entity,
    this.onConfirm,
  });

  final InstallPackageEntity entity;
  final void Function(String version, String? remark)? onConfirm;

  @override
  State<EditPackageDialog> createState() => _EditPackageDialogState();
}

class _EditPackageDialogState extends State<EditPackageDialog> {
  static final RegExp _versionPattern = RegExp(r'^\d+\.\d+\.\d+\.\d+$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _versionController;
  late final TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _versionController = TextEditingController(text: widget.entity.version);
    _remarkController = TextEditingController(text: widget.entity.remark ?? '');
  }

  @override
  void dispose() {
    _versionController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final remark = _remarkController.text.trim();
    widget.onConfirm?.call(
      _versionController.text.trim(),
      remark.isEmpty ? null : remark,
    );
  }

  String? _validateVersion(String? value) {
    final version = value?.trim() ?? '';
    if (version.isEmpty) {
      return '请输入版本号';
    }
    if (!_versionPattern.hasMatch(version)) {
      return '格式应为 0.1.1.1';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑安装包'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('edit_version_field'),
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: '版本号',
                hintText: '0.1.1.1',
              ),
              validator: _validateVersion,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('edit_remark_field'),
              controller: _remarkController,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('edit_file_field'),
              initialValue: widget.entity.fileName,
              readOnly: true,
              decoration: const InputDecoration(labelText: '文件名称'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
