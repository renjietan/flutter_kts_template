import 'package:flutter/material.dart';

class PlutoCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PlutoCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          // 白色框线：side 宽度 + color
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          // 背景色透明
          color: Colors.transparent,
        ),
        child: value
            ? Center(
          child: Icon(
            Icons.check,
            size: 16,
            // 勾选状态勾的颜色要求
            color: Color.fromRGBO(30, 35, 40, 1),
          ),
        )
            : null,
      ),
    );
  }
}