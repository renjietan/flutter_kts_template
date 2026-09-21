// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installPackageEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallPackageEntity _$InstallPackageEntityFromJson(
  Map<String, dynamic> json,
) => InstallPackageEntity(
  id: (json['id'] as num?)?.toInt() ?? 0,
  version: json['version'] as String,
  fileName: json['fileName'] as String,
  remark: json['remark'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$InstallPackageEntityToJson(
  InstallPackageEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'version': instance.version,
  'fileName': instance.fileName,
  'remark': instance.remark,
  'createdAt': instance.createdAt.toIso8601String(),
};
