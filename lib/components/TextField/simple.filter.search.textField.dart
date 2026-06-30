import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';

// =============================================================================
// 2026/6/30 下午6:12  搜索框
// =============================================================================
class SimpleFilterSearchField extends StatelessWidget {
  final String value;

  final ValueChanged<String> onChanged;

  final ValueChanged<String>? onSubmit;

  final String hint;

  final double width;

  final double height;

  final TextEditingController? controller;

  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  const SimpleFilterSearchField({
    super.key,
    this.value = '',
    required this.onChanged,
    this.hint = 'Search...',
    this.width = 280,
    this.height = 40,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.textMutedColor),
          prefixIcon: Icon(Icons.search, size: 18, color: theme.textMutedColor),
          filled: true,
          fillColor: theme.backgroundColor,
          contentPadding: EdgeInsets.zero,
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
