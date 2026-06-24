// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radios.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadiosEntity _$RadiosEntityFromJson(Map<String, dynamic> json) => RadiosEntity(
  id: (json['id'] as num?)?.toInt() ?? 0,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$RadiosEntityToJson(RadiosEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
