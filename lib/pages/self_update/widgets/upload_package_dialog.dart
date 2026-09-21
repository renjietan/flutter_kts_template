import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_kts_template/components/TextField/simple.form.textfield.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';

/// 文件上传弹窗（样式对齐电台管理）。
///
/// 三个区域：
/// - version：必填，仅数字，格式 `0.1.1.1`（点分四段）；
/// - 备注：textarea，选填，最长 150 字；
/// - 文件上传：只读框 + 【上传】按钮，上传中按钮显示 loading。
class UploadPackageDialog extends StatefulWidget {
  const UploadPackageDialog({
    super.key,
    this.onPickFile,
    this.onConfirm,
  });

  /// 选择/上传文件，返回文件名；取消返回 null，失败抛出异常。
  final Future<String?> Function()? onPickFile;

  /// 校验通过后回调（version、备注、文件名）。
  final void Function(String version, String? remark, String fileName)?
  onConfirm;

  @override
  State<UploadPackageDialog> createState() => _UploadPackageDialogState();
}

class _UploadPackageDialogState extends State<UploadPackageDialog> {
  static final RegExp _versionPattern = RegExp(r'^\d+\.\d+\.\d+\.\d+$');

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  bool _uploading = false;

  @override
  void dispose() {
    _versionController.dispose();
    _remarkController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final onPickFile = widget.onPickFile;
    if (onPickFile == null || _uploading) {
      return;
    }
    setState(() {
      _uploading = true;
    });
    try {
      final name = await onPickFile();
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
        _fileNameController.text = name ?? '';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final remark = _remarkController.text.trim();
    widget.onConfirm?.call(
      _versionController.text.trim(),
      remark.isEmpty ? null : remark,
      _fileNameController.text.trim(),
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

  String? _validateFile(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return '请先上传安装包';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: const Text(
        '上传安装包',
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
                key: const ValueKey('version_field'),
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
                key: const ValueKey('remark_field'),
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
              _buildFieldLabel('安装包'),
              const SizedBox(height: 8),
              DataTablePlusThemeProvider(
                theme: getThemePreset(ThemePreset.dark),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SimpleFormTextField(
                        key: const ValueKey('file_field'),
                        field: FormFieldConfig(
                          name: 'fileName',
                          label: '安装包',
                          hintText: '请选择 ZIP 安装包',
                          textEditingController: _fileNameController,
                          readonly: true,
                          validators: [_validateFile],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BaseButton(
                      label: '上传',
                      minWidth: 80,
                      isLoading: _uploading,
                      onPressed: _uploading ? null : _pickFile,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        BaseButton(label: '确定', minWidth: 100, onPressed: _submit),
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
