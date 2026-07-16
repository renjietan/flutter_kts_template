import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/table/simple.table.mixin.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';

class SimpleTable extends StatefulWidget {
  final ThemePreset themePreset;
  const SimpleTable({super.key, this.themePreset = ThemePreset.dark});

  @override
  State<SimpleTable> createState() => _SimpleTableState();
}

class _SimpleTableState extends State<SimpleTable> with SimpleTableMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
