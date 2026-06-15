import 'dart:ui';

import 'package:composable_data_table/composable_data_table.dart';

// =============================================================================
// 2026/6/15 composable_data_table 的主题定制,具体细节参照 pub.dev
// =============================================================================
enum ThemePreset { light, dark, blue, green, purple }

DataTablePlusTheme getThemePreset(ThemePreset preset) {
  switch (preset) {
    case ThemePreset.light:
      return DataTablePlusTheme.defaultTheme;
    case ThemePreset.dark:
      return const DataTablePlusTheme(
        backgroundColor: Color(0xFF1E1E1E),
        headerBackgroundColor: Color(0xFF2D2D2D),
        borderColor: Color(0xFF404040),
        borderLightColor: Color(0xFF333333),
        textPrimaryColor: Color(0xFFE0E0E0),
        textSecondaryColor: Color(0xFFB0B0B0),
        textMutedColor: Color(0xFF808080),
        accentColor: Color(0xFF64B5F6),
        accentLightColor: Color(0xFF1E3A5F),
        successColor: Color(0xFF81C784),
        successLightColor: Color(0xFF1B3D1B),
        warningColor: Color(0xFFFFB74D),
        warningLightColor: Color(0xFF4D3800),
        dangerColor: Color(0xFFE57373),
        dangerLightColor: Color(0xFF4D1F1F),
      );
    case ThemePreset.blue:
      return const DataTablePlusTheme(
        backgroundColor: Color(0xFFF0F7FF),
        headerBackgroundColor: Color(0xFFDBEAFE),
        borderColor: Color(0xFFBFDBFE),
        borderLightColor: Color(0xFFE0EFFE),
        textPrimaryColor: Color(0xFF1E3A5F),
        textSecondaryColor: Color(0xFF3B6BA5),
        textMutedColor: Color(0xFF7BA4CC),
        accentColor: Color(0xFF2563EB),
        accentLightColor: Color(0xFFDBEAFE),
        successColor: Color(0xFF059669),
        successLightColor: Color(0xFFD1FAE5),
        warningColor: Color(0xFFD97706),
        warningLightColor: Color(0xFFFEF3C7),
        dangerColor: Color(0xFFDC2626),
        dangerLightColor: Color(0xFFFEE2E2),
      );
    case ThemePreset.green:
      return const DataTablePlusTheme(
        backgroundColor: Color(0xFFF0FDF4),
        headerBackgroundColor: Color(0xFFDCFCE7),
        borderColor: Color(0xFFBBF7D0),
        borderLightColor: Color(0xFFD1FAE5),
        textPrimaryColor: Color(0xFF14532D),
        textSecondaryColor: Color(0xFF166534),
        textMutedColor: Color(0xFF6DA88A),
        accentColor: Color(0xFF16A34A),
        accentLightColor: Color(0xFFDCFCE7),
        successColor: Color(0xFF16A34A),
        successLightColor: Color(0xFFDCFCE7),
        warningColor: Color(0xFFCA8A04),
        warningLightColor: Color(0xFFFEF9C3),
        dangerColor: Color(0xFFDC2626),
        dangerLightColor: Color(0xFFFEE2E2),
      );
    case ThemePreset.purple:
      return const DataTablePlusTheme(
        backgroundColor: Color(0xFFFAF5FF),
        headerBackgroundColor: Color(0xFFF3E8FF),
        borderColor: Color(0xFFE9D5FF),
        borderLightColor: Color(0xFFF3E8FF),
        textPrimaryColor: Color(0xFF3B0764),
        textSecondaryColor: Color(0xFF6B21A8),
        textMutedColor: Color(0xFFA78BFA),
        accentColor: Color(0xFF9333EA),
        accentLightColor: Color(0xFFF3E8FF),
        successColor: Color(0xFF059669),
        successLightColor: Color(0xFFD1FAE5),
        warningColor: Color(0xFFD97706),
        warningLightColor: Color(0xFFFEF3C7),
        dangerColor: Color(0xFFDC2626),
        dangerLightColor: Color(0xFFFEE2E2),
      );
  }
}

Color getScaffoldBg(ThemePreset preset) {
  switch (preset) {
    case ThemePreset.dark:
      return const Color(0xFF121212);
    case ThemePreset.blue:
      return const Color(0xFFE8F0FE);
    case ThemePreset.green:
      return const Color(0xFFE8F5E9);
    case ThemePreset.purple:
      return const Color(0xFFF3E5F5);
    default:
      return const Color(0xFFF5F5F5);
  }
}

