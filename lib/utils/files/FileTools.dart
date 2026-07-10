import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/utils/files/exception/FileException.dart';
import 'package:path/path.dart' as p;

class ArchiveEntry {
  final String sourcePath; // 磁盘上的真实文件路径
  final String innerDir; // 希望它在归档里的文件夹路径，例如 "3_device_config"

  ArchiveEntry({required this.sourcePath, required this.innerDir});
}

enum ArchiveEncoderType { zip, tar, tarGz }

class FileTools {
  static Future<List<Directory>> getDirectSubFolders(String parentPath) async {
    final parentDir = Directory(parentPath);

    if (!await parentDir.exists()) {
      throw FileException(t.uploads.emptyPath);
    }

    final List<FileSystemEntity> entities = await parentDir.list().toList();

    final List<Directory> subDirs = entities
        .whereType<Directory>()
        .map((entity) => entity)
        .toList();

    return subDirs;
  }

  /// [directoryPath] 读取路径下的所有 JSON 文件。
  ///
  /// [recursive]：是否递归子目录（默认 false）。
  /// [includeExtension]：键名是否包含文件扩展名（默认 false，只取文件名），例如 111.zip: xxxx
  ///
  /// 返回 Map，键为文件名，值为解析后的 JSON 对象（Map 或 List）。
  static Future<Map<String, dynamic>> readAllJsonFiles(
    Directory directory, {
    bool recursive = false,
    bool includeExtension = false,
  }) async {
    if (!await directory.exists()) {
      throw FileException(t.uploads.existPath);
    }

    final result = <String, dynamic>{};

    await for (final entity in directory.list(
      recursive: recursive,
      followLinks: false,
    )) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.json') {
        var content = "";
        try {
          content = await entity.readAsString(encoding: utf8);
          final jsonData = jsonDecode(content);
          final key = includeExtension
              ? p.basename(entity.path)
              : p.basenameWithoutExtension(entity.path);
          result[key] = jsonData;
        } catch (e) {
          throw FileException(t.json.serialization);
        }
      }
    }
    return result;
  }

  static Future<void> extractZipToDisk({
    required List<ArchiveEntry> entries,
    required String outputPath,
    required String zipName,
    ArchiveEncoderType type = ArchiveEncoderType.zip,
  }) async {
    final archive = Archive();

    for (final entry in entries) {
      final file = File(entry.sourcePath);
      if (!await file.exists()) continue;

      final bytes = await file.readAsBytes();
      final fileName = file.uri.pathSegments.last;
      final innerPath = entry.innerDir.isEmpty
          ? fileName
          : '${entry.innerDir}/$fileName';

      archive.addFile(ArchiveFile(innerPath, bytes.length, bytes));
    }

    List<int>? data;
    String extension = "";
    switch (type) {
      case ArchiveEncoderType.zip:
        data = ZipEncoder().encode(archive);
        extension = ".zip";
        break;
      case ArchiveEncoderType.tar:
        data = TarEncoder().encode(archive);
        extension = ".tar";
        break;
      case ArchiveEncoderType.tarGz:
        final tarData = TarEncoder().encode(archive);
        data = GZipEncoder().encode(tarData);
        extension = ".tar.gz";
        break;
    }
    String savePath = p.join(outputPath, "$zipName$extension");
    await File(savePath).writeAsBytes(data);
  }
}
