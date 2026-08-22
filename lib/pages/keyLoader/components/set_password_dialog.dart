import 'package:flutter/material.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

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
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final text = value ?? '';
    final t = Translations.of(context);
    if (text.isEmpty) return t.cpds.setPassword.required;
    if (text.length < 6) return t.cpds.setPassword.minLength;
    if (text.length > 20) return t.cpds.setPassword.maxLength;
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return t.cpds.setPassword.noChinese;
    }
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(text) ||
        text.contains('\u0000') ||
        text.contains('\r') ||
        text.contains('\n')) {
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
    return AlertDialog(
      backgroundColor: const Color(0xFF20262D),
      title: Text(
        t.cpds.setPassword.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: _validate,
          decoration: InputDecoration(
            labelText: t.cpds.setPassword.label,
            hintText: t.cpds.setPassword.placeholder,
            labelStyle: const TextStyle(color: Colors.white),
            hintStyle: const TextStyle(color: Colors.white38),
            suffixIcon: IconButton(
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(t.common.confirm),
        ),
      ],
    );
  }
}
