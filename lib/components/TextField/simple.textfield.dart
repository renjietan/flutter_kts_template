import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';

class SimpleTextfield extends StatelessWidget {
  final String value;

  final ValueChanged<String>? onChanged;

  final String hint;

  final double width;

  final double height;

  final TextEditingController? controller;

  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  final Widget? prefixIconWidget;

  final EdgeInsets? contentPadding;

  const SimpleTextfield({
    super.key,
    this.value = '',
    this.onChanged,
    this.hint = 'Search...',
    this.width = 280,
    this.height = 40,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.prefixIconWidget,
    this.contentPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    // 沿用表格插件 composable_data_table 的主题
    final theme = DataTablePlusThemeProvider.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: TextStyle(fontSize: 13, color: theme.textPrimaryColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.textMutedColor),
          prefixIcon: prefixIconWidget,
          filled: true,
          fillColor: theme.backgroundColor,
          contentPadding: contentPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadiusSmall),
            borderSide: BorderSide(color: theme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadiusSmall),
            borderSide: BorderSide(color: theme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadiusSmall),
            borderSide: BorderSide(color: theme.accentColor),
          ),
        ),
      ),
    );
  }
}
