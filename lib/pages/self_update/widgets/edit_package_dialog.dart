// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/TextField/simple.form.textfield.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/utils/arabic_digits.dart';

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
      return t.selfUpdate.versionRequired;
    }
    if (!_versionPattern.hasMatch(version)) {
      return t.selfUpdate.versionFormat;
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
      title: Text(
        t.selfUpdate.editTitle,
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
              _buildFieldLabel(t.selfUpdate.version, required: true),
              const SizedBox(height: 8),
              SimpleFormTextField(
                key: const ValueKey('edit_version_field'),
                field: FormFieldConfig(
                  name: 'version',
                  label: t.selfUpdate.version,
                  hintText: localizeDigits(context, t.selfUpdate.versionHint),
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
              _buildFieldLabel(t.selfUpdate.remarkOptional),
              const SizedBox(height: 8),
              SimpleFormTextField(
                key: const ValueKey('edit_remark_field'),
                field: FormFieldConfig(
                  name: 'remark',
                  label: t.selfUpdate.remarkOptional,
                  hintText: t.selfUpdate.remarkHint,
                  textEditingController: _remarkController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 3,
                  inputFormatters: [LengthLimitingTextInputFormatter(150)],
                  counterTextBuilder: (value) => localizeDigits(context, '${value.length}/150'),
                ),
              ),
              const SizedBox(height: 16),
              _buildFieldLabel(t.selfUpdate.packageLabel, required: true),
              const SizedBox(height: 8),
              SimpleFormTextField(
                key: const ValueKey('edit_file_field'),
                field: FormFieldConfig(
                  name: 'fileName',
                  label: t.selfUpdate.packageLabel,
                  hintText: t.selfUpdate.packageLabel,
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
          child: Text(
            t.selfUpdate.cancel,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        BaseButton(
          label: t.selfUpdate.ok,
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
