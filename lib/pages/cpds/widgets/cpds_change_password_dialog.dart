import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cpds_messages.dart';

/// 修改 `.pc` 密码的弹窗：原密码 + 新密码 + 确认新密码。
class CpdsChangePasswordDialog extends StatefulWidget {
  const CpdsChangePasswordDialog({super.key, required this.onSubmit});

  /// 返回 null 表示成功；返回字符串表示错误信息（弹窗内展示）。
  final Future<String?> Function(String oldPassword, String newPassword)
      onSubmit;

  @override
  State<CpdsChangePasswordDialog> createState() =>
      _CpdsChangePasswordDialogState();
}

class _CpdsChangePasswordDialogState
    extends State<CpdsChangePasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _oldController.addListener(_onChanged);
    _newController.addListener(_onChanged);
    _confirmController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _oldController.removeListener(_onChanged);
    _newController.removeListener(_onChanged);
    _confirmController.removeListener(_onChanged);
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String? _validate8Digits(String? value, String required, String invalid) {
    final text = value ?? '';
    if (text.isEmpty) return required;
    if (!RegExp(r'^\d{8}$').hasMatch(text)) return invalid;
    return null;
  }

  String? _validateConfirm(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return CpdsMessages.tr(
        context,
        '请再次输入新密码',
        'Please enter the new password again',
        'يرجى إدخال كلمة المرور الجديدة مرة أخرى',
      );
    }
    if (text != _newController.text) {
      return CpdsMessages.tr(
        context,
        '两次输入的新密码不一致',
        'The two new passwords do not match',
        'كلمتا المرور الجديدتان غير متطابقتين',
      );
    }
    return null;
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    final error = await widget.onSubmit(
      _oldController.text,
      _newController.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _loading = false;
      _errorText = error;
    });
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '* ',
                  style: TextStyle(color: Colors.red),
                ),
                TextSpan(
                  text: label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: _obscure,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${controller.text.length}/8',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                ),
              ],
            ),
            filled: true,
            fillColor: const Color(0xFF282D33),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF353A41)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF00A2E9)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        CpdsMessages.tr(
          context,
          '修改密码',
          'Change Password',
          'تغيير كلمة المرور',
        ),
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField(
                label: CpdsMessages.tr(context, '原密码', 'Old Password', 'كلمة المرور القديمة'),
                hint: CpdsMessages.tr(context, '请输入原密码', 'Please enter the old password', 'يرجى إدخال كلمة المرور القديمة'),
                controller: _oldController,
                validator: (value) => _validate8Digits(
                  value,
                  CpdsMessages.tr(context, '请输入原密码', 'Please enter the old password', 'يرجى إدخال كلمة المرور القديمة'),
                  CpdsMessages.tr(context, '只允许输入八位数字', 'Only 8 digits are allowed', 'يُسمح فقط بإدخال ثمانية أرقام'),
                ),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: CpdsMessages.tr(context, '新密码', 'New Password', 'كلمة المرور الجديدة'),
                hint: CpdsMessages.tr(context, '请输入新密码', 'Please enter the new password', 'يرجى إدخال كلمة المرور الجديدة'),
                controller: _newController,
                validator: (value) => _validate8Digits(
                  value,
                  CpdsMessages.tr(context, '请输入新密码', 'Please enter the new password', 'يرجى إدخال كلمة المرور الجديدة'),
                  CpdsMessages.tr(context, '只允许输入八位数字', 'Only 8 digits are allowed', 'يُسمح فقط بإدخال ثمانية أرقام'),
                ),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: CpdsMessages.tr(context, '确认新密码', 'Confirm New Password', 'تأكيد كلمة المرور الجديدة'),
                hint: CpdsMessages.tr(context, '请再次输入新密码', 'Please enter the new password again', 'يرجى إدخال كلمة المرور الجديدة مرة أخرى'),
                controller: _confirmController,
                validator: _validateConfirm,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorText!,
                    style: const TextStyle(color: Color(0xFFF15B64), fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            CpdsMessages.tr(context, '取消', 'Cancel', 'إلغاء'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  CpdsMessages.tr(context, '确定', 'Confirm', 'تأكيد'),
                ),
        ),
      ],
    );
  }
}
