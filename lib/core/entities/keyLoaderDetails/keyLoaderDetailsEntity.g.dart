// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyLoaderDetailsEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyLoaderDetailsEntity _$KeyLoaderDetailsEntityFromJson(
  Map<String, dynamic> json,
) => KeyLoaderDetailsEntity(
  id: (json['id'] as num?)?.toInt() ?? 0,
  netNodePackageName: json['netNodePackageName'] as String,
  dcPackageName: json['dcPackageName'] as String,
  keyLoaderId: (json['keyLoaderId'] as num).toInt(),
  radioId: (json['radioId'] as num?)?.toInt(),
  consumer: json['consumer'] as String?,
  location: json['location'] as String?,
  SN: json['SN'] as String?,
  parentIdPath: json['parentIdPath'] as String? ?? '',
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$KeyLoaderDetailsEntityToJson(
  KeyLoaderDetailsEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'netNodePackageName': instance.netNodePackageName,
  'dcPackageName': instance.dcPackageName,
  'location': instance.location,
  'SN': instance.SN,
  'radioId': instance.radioId,
  'consumer': instance.consumer,
  'parentIdPath': instance.parentIdPath,
  'keyLoaderId': instance.keyLoaderId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
