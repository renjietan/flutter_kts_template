// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_button_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SetPasswordDialog extends StatefulWidget {
  const SetPasswordDialog({super.key});

  @override
  State<SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<SetPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  String? _validate(String? value) {
    final text = value ?? '';
    final t = Translations.of(context);
    if (text.isEmpty) return t.cpds.setPassword.required;
    if (!RegExp(r'^\d{8}$').hasMatch(text)) {
      return t.cpds.setPassword.invalid;
    }
    return null;
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final password = _passwordController.text;
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = bottomInset > 0;
    final keyboardHeight = bottomInset;
    return AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        t.cpds.setPassword.title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: _validate,
          decoration: InputDecoration(
            labelText: t.cpds.setPassword.label,
            hintText: t.cpds.setPassword.placeholder,
            labelStyle: const TextStyle(color: Colors.white),
            hintStyle: const TextStyle(color: Colors.white38),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_passwordController.text.length}/8',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ],
            ),
            filled: true,
            fillColor: const Color(0xFF282D33),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
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
      ),
      actions: keyboardVisible
          ? [Padding(padding: EdgeInsets.only(bottom: 1.h))]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  t.common.cancel,
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                ),
              ),
              FilledButton(
                style: cpdsFilledButtonStyle(),
                onPressed: _confirm,
                child: Text(t.common.confirm),
              ),
            ],
    );
  }
}
