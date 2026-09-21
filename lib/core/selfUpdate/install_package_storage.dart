import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:path/path.dart' as p;

/// 自更新安装包的文件存储服务。
///
/// 负责 install 目录下的 ZIP 保存、解压归一化（统一为 `install_yyyyMMdd_HHmmss`
/// 目录）以及删除。
///
/// 通过构造注入 [installDirectory] 以便单测使用临时目录，不依赖全局路径。
class InstallPackageStorage {
  InstallPackageStorage({Directory? installDirectory})
    : _installDirectoryOverride = installDirectory;

  final Directory? _installDirectoryOverride;

  /// 生成上传文件名/文件夹名前缀，形如 `install_20260919_123456`。
  static String formatBaseName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'install_${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<Directory> _installDir() async {
    final override = _installDirectoryOverride;
    if (override != null) {
      return override;
    }
    return DirectoryManager.instance.getUploadsDirectory(subDir: 'install');
  }

  /// 保存 ZIP 到 `<install>/<baseName>.zip`。
  Future<File> saveZip(Uint8List bytes, {required String baseName}) async {
    final installDir = await _installDir();
    if (!await installDir.exists()) {
      await installDir.create(recursive: true);
    }
    final file = File(p.join(installDir.path, '$baseName.zip'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// 读取 `<install>/<baseName>.zip` 并解压，归一化到 `<install>/<baseName>`。
  ///
  /// 规则：
  /// - 解压后只有 1 个文件夹 → 将该文件夹重命名为 baseName；
  /// - 否则（多个文件夹或混合内容）→ 新建 baseName 文件夹并移入全部内容。
  Future<Directory> extractZip({required String baseName}) async {
    final installDir = await _installDir();
    if (!await installDir.exists()) {
      await installDir.create(recursive: true);
    }
    final zipFile = File(p.join(installDir.path, '$baseName.zip'));
    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());

    // 使用 install 目录内部的 staging，保证后续 rename 始终在同一文件系统，
    // 避免 Windows 跨盘或 Android 跨挂载点 rename 失败。
    final staging = Directory(p.join(installDir.path, '.staging_$baseName'));
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    await staging.create(recursive: true);
    try {
      await extractArchiveToDisk(archive, staging.path);

      final entries = staging.listSync();
      final target = Directory(p.join(installDir.path, baseName));
      if (await target.exists()) {
        await target.delete(recursive: true);
      }

      if (entries.length == 1 && entries.single is Directory) {
        await entries.single.rename(target.path);
      } else {
        await target.create(recursive: true);
        for (final entry in entries) {
          await entry.rename(p.join(target.path, p.basename(entry.path)));
        }
      }
      return target;
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  /// 删除 `<install>/<baseName>.zip` 与 `<install>/<baseName>` 文件夹。
  Future<void> delete({required String baseName}) async {
    final installDir = await _installDir();
    final zipFile = File(p.join(installDir.path, '$baseName.zip'));
    if (await zipFile.exists()) {
      await zipFile.delete();
    }
    final folder = Directory(p.join(installDir.path, baseName));
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  /// 判断安装包（ZIP 或解压目录）是否仍存在。
  Future<bool> packageExists(String fileName) async {
    final installDir = await _installDir();
    final zipFile = File(p.join(installDir.path, fileName));
    if (await zipFile.exists()) {
      return true;
    }
    final baseName = p.basenameWithoutExtension(fileName);
    final folder = Directory(p.join(installDir.path, baseName));
    return await folder.exists();
  }

  /// 读取解压目录「二级目录」下各 `cpdc_config.json` 根节点 version。
  ///
  /// 返回「二级目录名 → version」映射（目录名即设备类型目录名）。
  Future<Map<String, String>> readPackageVersions(String baseName) async {
    final installDir = await _installDir();
    final root = Directory(p.join(installDir.path, baseName));
    final versions = <String, String>{};
    if (!await root.exists()) {
      return versions;
    }

    await for (final entity in root.list()) {
      if (entity is! Directory) {
        continue;
      }
      final configFile = File(p.join(entity.path, 'cpdc_config.json'));
      if (!await configFile.exists()) {
        continue;
      }
      try {
        final json = jsonDecode(await configFile.readAsString());
        final version = json is Map<String, dynamic> ? json['version'] : null;
        if (version is String && version.isNotEmpty) {
          versions[p.basename(entity.path)] = version;
        }
      } catch (_) {
        // 单个损坏的配置不影响其它目录。
      }
    }
    return versions;
  }

  /// 回写解压目录各二级目录下 generic `cpdc_config.json` 的 version 字段。
  ///
  /// 仅修改 `cpdc_config.json`，不改 `cpdc_config.<类型>.json`。
  Future<void> rewritePackageVersions({
    required String baseName,
    required String version,
  }) async {
    final installDir = await _installDir();
    final root = Directory(p.join(installDir.path, baseName));
    if (!await root.exists()) {
      return;
    }

    await for (final entity in root.list()) {
      if (entity is! Directory) {
        continue;
      }
      final configFile = File(p.join(entity.path, 'cpdc_config.json'));
      if (!await configFile.exists()) {
        continue;
      }
      try {
        final json = jsonDecode(await configFile.readAsString());
        if (json is Map<String, dynamic>) {
          json['version'] = version;
          await configFile.writeAsString(jsonEncode(json));
        }
      } catch (_) {
        // 单个目录写入失败不阻塞其它目录。
      }
    }
  }

  /// 把指定设备类型对应的二级文件夹打包成一个 ZIP。
  ///
  /// ZIP 内保持 `类型文件夹/文件` 的相对结构，供 CPDC 解压后按类型匹配。
  Future<Uint8List> buildTypeZip({
    required String baseName,
    required Set<String> deviceTypes,
  }) async {
    final installDir = await _installDir();
    final root = Directory(p.join(installDir.path, baseName));
    final archive = Archive();

    for (final type in deviceTypes) {
      final typeDir = Directory(p.join(root.path, type));
      if (!await typeDir.exists()) {
        continue;
      }
      await for (final entity in typeDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }
        final relPath = p
            .relative(entity.path, from: root.path)
            .replaceAll('\\', '/');
        final content = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relPath, content.length, content));
      }
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
