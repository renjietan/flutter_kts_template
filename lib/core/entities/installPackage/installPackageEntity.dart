import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'installPackageEntity.g.dart';

/// 自更新安装包记录。
///
/// 对应上传页面的一行：版本号、文件名称、备注、创建时间。
@Entity()
@JsonSerializable()
class InstallPackageEntity {
  @Id()
  @JsonKey(defaultValue: 0)
  int id;

  /// 版本号，形如 "0.1.1.1"（点分四段）。
  ///
  /// 业务上视为业务主键：相同 version 时「覆盖」已有记录。
  String version;

  /// 上传后的 ZIP 文件名，形如 "install_yyyyMMdd_HHmmss.zip"。
  String fileName;

  /// 备注（非必填，最长 150 字）。
  String? remark;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  InstallPackageEntity({
    this.id = 0,
    required this.version,
    required this.fileName,
    this.remark,
    required this.createdAt,
  });

  factory InstallPackageEntity.fromJson(Map<String, dynamic> json) =>
      _$InstallPackageEntityFromJson(json);

  Map<String, dynamic> toJson() => _$InstallPackageEntityToJson(this);
}
