// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NetNodeFileEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetNodeFileEntity _$NetNodeFileEntityFromJson(Map<String, dynamic> json) =>
    NetNodeFileEntity(
      description: json['description'] as String?,
      guid: json['guid'] as String?,
      layer: json['layer'] as String?,
      model: json['model'] as String?,
    );

Map<String, dynamic> _$NetNodeFileEntityToJson(NetNodeFileEntity instance) =>
    <String, dynamic>{
      'description': ?instance.description,
      'guid': ?instance.guid,
      'layer': ?instance.layer,
      'model': ?instance.model,
    };
