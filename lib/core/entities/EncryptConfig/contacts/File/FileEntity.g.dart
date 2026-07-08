// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'FileEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileEntity _$FileEntityFromJson(Map<String, dynamic> json) => FileEntity(
  layer: json['Layer'] as String?,
  guid: json['Guid'] as String?,
  description: json['Description'] as String?,
);

Map<String, dynamic> _$FileEntityToJson(FileEntity instance) =>
    <String, dynamic>{
      'Layer': instance.layer,
      'Guid': instance.guid,
      'Description': instance.description,
    };
