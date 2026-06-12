import 'package:flutter/cupertino.dart';

/// 菜单项数据模型
class MenuItem {
  final IconData icon;
  final String label;

  const MenuItem({
    required this.icon,
    required this.label,
  });
}