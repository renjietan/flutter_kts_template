// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'KeyFileEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyFileEntity _$KeyFileEntityFromJson(Map<String, dynamic> json) =>
    KeyFileEntity(
      layer: json['layer'] as String?,
      type: json['type'] as String?,
      guid: (json['guid'] as num?)?.toInt(),
      description: (json['description'] as num?)?.toInt(),
    );

Map<String, dynamic> _$KeyFileEntityToJson(KeyFileEntity instance) =>
    <String, dynamic>{
      'layer': ?instance.layer,
      'type': ?instance.type,
      'guid': ?instance.guid,
      'description': ?instance.description,
    };
