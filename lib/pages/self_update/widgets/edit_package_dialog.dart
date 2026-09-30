import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/TextField/simple.form.textfield.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';

/// 编辑安装包信息弹窗（样式对齐文件上传弹窗）。
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

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final TextEditingController _versionController;
  late final TextEditingController _remarkController;
  late final TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    _versionController = TextEditingController(text: widget.entity.version);
    _remarkController = TextEditingController(text: widget.entity.remark ?? '');
    _fileNameController = TextEditingController(text: widget.entity.fileName);
  }

  @override
  void dispose() {
    _versionController.dispose();
    _remarkController.dispose();
    _fileNameController.dispose();
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
      backgroundColor: const Color(0xFF20262D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: const Text(
        '编辑安装包',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      content: SizedBox(
        width: 560,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFieldLabel('版本号', required: true),
              const SizedBox(height: 8),
              SimpleFormTextField(
                key: const ValueKey('edit_version_field'),
                field: FormFieldConfig(
                  name: 'version',
                  label: '版本号',
                  hintText: '0.1.1.1',
                  textEditingController: _versionController,
                  required: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    LengthLimitingTextInputFormatter(30),
                  ],
                  validators: [_validateVersion],
                ),
              ),
              const SizedBox(height: 16),
              _buildFieldLabel('备注（选填）'),
              const SizedBox(height: 8),
              SimpleFormTextField(
                key: const ValueKey('edit_remark_field'),
                field: FormFieldConfig(
                  name: 'remark',
                  label: '备注（选填）',
                  hintText: '请输入备注',
                  textEditingController: _remarkController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 3,
                  inputFormatters: [LengthLimitingTextInputFormatter(150)],
                  counterTextBuilder: (value) => '${value.length}/150',
                ),
              ),
              const SizedBox(height: 16),
              _buildFieldLabel('安装包', required: true),
              const SizedBox(height: 8),
              SimpleFormTextField(
                key: const ValueKey('edit_file_field'),
                field: FormFieldConfig(
                  name: 'fileName',
                  label: '安装包',
                  hintText: '安装包',
                  textEditingController: _fileNameController,
                  readonly: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        BaseButton(
          label: '确定',
          minWidth: 100,
          borderRadius: 5,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text, {bool required = false}) {
    return Container(
      alignment: AlignmentDirectional.centerStart,
      child: required
          ? Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '* ',
                    style: TextStyle(color: Colors.red),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            )
          : Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
    );
  }
}
