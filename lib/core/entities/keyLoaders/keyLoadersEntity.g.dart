// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyLoadersEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyLoadersEntity _$KeyLoadersEntityFromJson(Map<String, dynamic> json) =>
    KeyLoadersEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$KeyLoadersEntityToJson(KeyLoadersEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
