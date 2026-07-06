import 'package:flutter/material.dart';

class TextTitle extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  const TextTitle({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: fontSize ?? 18,
        fontWeight: fontWeight ?? FontWeight.w500,
      ),
    );
  }
}
