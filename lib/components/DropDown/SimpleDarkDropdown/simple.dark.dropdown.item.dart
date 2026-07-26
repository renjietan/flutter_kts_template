import 'package:flutter/cupertino.dart';

/// 下拉菜单项
class SimpleDarkDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SimpleDarkDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}
