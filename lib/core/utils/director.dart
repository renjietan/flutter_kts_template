import 'dart:io';

import 'package:flutter_kts_template/config/config.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DirectoryManager {
  DirectoryManager._();

  static final DirectoryManager _instance = DirectoryManager._();

  static DirectoryManager get instance => _instance;

  Directory? _cachedBaseDir;

  /// 获取上传目录（可指定子目录）
  Future<Directory> getUploadsDirectory({String? subDir}) async {
    final baseDir = await _getBaseDirectory();

    if (subDir == null) {
      return baseDir;
    }

    final subDirObj = Directory(path.join(baseDir.path, subDir));
    if (!await subDirObj.exists()) {
      await subDirObj.create(recursive: true);
    }
    return subDirObj;
  }

  Future<String> getStaticPath() async {
    final dir = await getUploadsDirectory(subDir: "static");
    return dir.path;
  }

  Future<String> getUploadsPath() async {
    final dir = await getUploadsDirectory(subDir: "uploads");
    return dir.path;
  }

  Future<String> getZipCache() async {
    final dir = await getUploadsDirectory(subDir: "zipCache");
    return dir.path;
  }

  Future<String> getDataBasePath() async {
    final dir = await getUploadsDirectory(
      subDir: AppConfig.dataBaseConfig.name,
    );
    return dir.path;
  }

  /// 获取基础目录（缓存 + 懒加载）
  Future<Directory> _getBaseDirectory() async {
    if (_cachedBaseDir != null) {
      return _cachedBaseDir!;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory(path.join(appDocDir.path, AppConfig.appName));

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    _cachedBaseDir = baseDir;
    return baseDir;
  }
}
