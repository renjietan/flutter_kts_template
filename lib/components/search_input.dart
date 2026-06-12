import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchText extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final IconData searchIcon;

  const SearchText({
    super.key,
    this.controller,
    this.hintText = '搜索',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.searchIcon = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    // 固定背景色
    const backgroundColor = Color(0xFF172622); // rgba(23,38,34,1)

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      enabled: enabled,
      style: const TextStyle(
        color: Colors.white, // 输入文字白色
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: backgroundColor,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white70, // 提示文字半透明白色
          fontSize: 14,
        ),
        // 右侧搜索图标（置于后面）
        suffixIcon: Icon(
          searchIcon,
          color: Colors.white70,
          size: 20,
        ),
        // 移除所有边框效果
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        // 确保文字不会覆盖图标：给右侧留出图标宽度+间距
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
      ),
    );
  }
}