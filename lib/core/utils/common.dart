import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 缓存目录对象，避免重复调用 getApplicationDocumentsDirectory
Directory? _cachedUploadsDir;

Future<Directory> getUploadsDirectory({String? subDir}) async {
  if (_cachedUploadsDir != null) {
    if (subDir != null) {
      return Directory(path.join(_cachedUploadsDir!.path, subDir));
    }
    return _cachedUploadsDir!;
  }

  final appDocDir = await getApplicationDocumentsDirectory();

  final baseUploadsDir = Directory(path.join(appDocDir.path, 'uploads'));

  if (!await baseUploadsDir.exists()) {
    await baseUploadsDir.create(recursive: true);
  }

  _cachedUploadsDir = baseUploadsDir;

  if (subDir != null) {
    final subDirObj = Directory(path.join(baseUploadsDir.path, subDir));
    if (!await subDirObj.exists()) {
      await subDirObj.create(recursive: true);
    }
    return subDirObj;
  }

  return baseUploadsDir;
}

Future<String> getUploadsPath({String? subDir}) async {
  final dir = await getUploadsDirectory(subDir: subDir);
  return dir.path;
}


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