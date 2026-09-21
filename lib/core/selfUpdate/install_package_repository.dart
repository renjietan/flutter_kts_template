import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/objectbox.g.dart';

/// 自更新安装包记录的数据访问层。
///
/// 通过构造注入 [Box] 以便在测试中传入临时 store，避免依赖全局单例。
class InstallPackageRepository {
  InstallPackageRepository(this._box);

  final Box<InstallPackageEntity> _box;

  /// 保存一条记录；相同 [InstallPackageEntity.version] 时覆盖旧记录。
  ///
  /// 返回保存后的实体 id。
  int save(InstallPackageEntity entity) {
    final existing = _box
        .query(InstallPackageEntity_.version.equals(entity.version))
        .build()
        .findFirst();
    if (existing != null) {
      entity.id = existing.id;
    }
    return _box.put(entity);
  }

  /// 按 id 更新已有实体（编辑场景，不做 version 覆盖判定）。
  int update(InstallPackageEntity entity) => _box.put(entity);

  InstallPackageEntity? findByVersion(String version) {
    return _box
        .query(InstallPackageEntity_.version.equals(version))
        .build()
        .findFirst();
  }

  /// 按创建时间降序返回全部记录（与页面默认排序一致）。
  List<InstallPackageEntity> getAll() {
    return _box
        .query()
        .order(InstallPackageEntity_.createdAt, flags: Order.descending)
        .build()
        .find();
  }

  bool delete(int id) => _box.remove(id);

  int count() => _box.count();
}
