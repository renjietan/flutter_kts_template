// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CpdsProgressBar extends StatelessWidget {
  const CpdsProgressBar({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 5.h,
            decoration: BoxDecoration(
              color: const Color(0xFF323941),
              borderRadius: BorderRadius.circular(3.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0074D9), Color(0xFF00A2E9)],
                  ),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '$clamped%',
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFFB7BCC6)),
        ),
      ],
    );
  }
}
