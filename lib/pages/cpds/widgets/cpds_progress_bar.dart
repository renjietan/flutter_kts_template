import 'package:flutter/material.dart';

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
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF323941),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0074D9), Color(0xFF00A2E9)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$clamped%',
          style: const TextStyle(fontSize: 11, color: Color(0xFFB7BCC6)),
        ),
      ],
    );
  }
}
