import 'dart:typed_data';

import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_repository.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:path/path.dart' as p;

/// 自更新安装包的上传与删除编排服务。
///
/// 把「保存 ZIP → 解压 → 入库（覆盖）」和「删除记录 + 删除文件」串起来，
/// 供 UI 层调用；文件选择（file_picker）等平台相关逻辑由上层完成。
class SelfUpdateService {
  SelfUpdateService({required this.repository, required this.storage});

  final InstallPackageRepository repository;
  final InstallPackageStorage storage;

  /// 保存并解压 ZIP，返回最终文件名（`install_yyyyMMdd_HHmmss.zip`）。
  Future<String> uploadZip(Uint8List bytes, {DateTime? now}) async {
    final baseName = InstallPackageStorage.formatBaseName(now ?? DateTime.now());
    await storage.saveZip(bytes, baseName: baseName);
    await storage.extractZip(baseName: baseName);
    return '$baseName.zip';
  }

  /// 入库；相同 version 时覆盖旧记录。
  Future<void> savePackage({
    required String version,
    String? remark,
    required String fileName,
    DateTime? createdAt,
  }) async {
    final baseName = p.basenameWithoutExtension(fileName);
    await storage.rewritePackageVersions(baseName: baseName, version: version);
    repository.save(
      InstallPackageEntity(
        version: version,
        fileName: fileName,
        remark: remark,
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
  }

  /// 编辑安装包信息（version 与备注），保留文件名称与创建时间。
  void updatePackage({
    required InstallPackageEntity entity,
    required String version,
    String? remark,
  }) {
    entity.version = version;
    entity.remark = remark;
    repository.update(entity);
  }

  /// 删除数据库记录，并删除对应 ZIP 与解压文件夹。
  Future<void> deletePackage(InstallPackageEntity entity) async {
    repository.delete(entity.id);
    final baseName = p.basenameWithoutExtension(entity.fileName);
    await storage.delete(baseName: baseName);
  }

  /// 判断安装包（ZIP 或解压目录）是否仍存在。
  Future<bool> packageExists(String fileName) {
    return storage.packageExists(fileName);
  }
}
