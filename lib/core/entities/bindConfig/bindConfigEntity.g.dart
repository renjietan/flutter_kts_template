// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bindConfigEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BindConfigEntity _$BindConfigEntityFromJson(Map<String, dynamic> json) =>
    BindConfigEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      netNodeId: json['netNodeId'] as String,
      deviceConfigId: json['deviceConfigId'] as String,
      keyLoaderId: json['keyLoaderId'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BindConfigEntityToJson(BindConfigEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'netNodeId': instance.netNodeId,
      'deviceConfigId': instance.deviceConfigId,
      'keyLoaderId': instance.keyLoaderId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
