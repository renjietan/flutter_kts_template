String sanitizeFileName(String originalName) {
  final illegalChars = RegExp(r'[<>:"/\\|?*]');
  String sanitized = originalName.replaceAll(illegalChars, '_');
  sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
  sanitized = sanitized.trim().replaceAll(RegExp(r'^_+|_+$'), '');
  if (sanitized.isEmpty) {
    sanitized = 'empty_name';
  }
  return sanitized;
}

num safeParseNum(dynamic value, {num defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is num) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return defaultValue;

    final parsed = double.tryParse(trimmed);
    if (parsed != null) {
      if (parsed % 1 == 0) {
        return parsed.toInt();
      }
      return parsed;
    }
    return defaultValue;
  }
  return defaultValue;
}
