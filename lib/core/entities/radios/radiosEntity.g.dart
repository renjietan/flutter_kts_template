// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radiosEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadiosEntity _$RadiosEntityFromJson(Map<String, dynamic> json) => RadiosEntity(
  id: (json['id'] as num?)?.toInt() ?? 0,
  consumer: json['consumer'] as String,
  location: json['location'] as String,
  sn: json['sn'] as String,
  alias: json['alias'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RadiosEntityToJson(RadiosEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'alias': instance.alias,
      'consumer': instance.consumer,
      'location': instance.location,
      'sn': instance.sn,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
