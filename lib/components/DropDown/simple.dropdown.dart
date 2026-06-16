import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';

class SimpleDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final String? label;

  final List<DropdownMenuItem<T>> items;

  final ValueChanged<T?> onChanged;

  final double height;

  const SimpleDropdown({
    super.key,
    required this.value,
    required this.hint,
    this.label,
    required this.items,
    required this.onChanged,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = DataTablePlusThemeProvider.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border.all(color: theme.borderColor),
        borderRadius: BorderRadius.circular(theme.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textSecondaryColor,
              ),
            ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(fontSize: 13, color: theme.textMutedColor),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: theme.textMutedColor,
                ),
                style: TextStyle(fontSize: 13, color: theme.textPrimaryColor),
                dropdownColor: theme.backgroundColor,
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
