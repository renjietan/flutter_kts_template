// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DapEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DapEntity _$DapEntityFromJson(Map<String, dynamic> json) => DapEntity(
  name: json['name'] as String?,
  result: (json['result'] as List<dynamic>?)
      ?.map((e) => DapResultEntity.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DapEntityToJson(DapEntity instance) => <String, dynamic>{
  'name': ?instance.name,
  'result': ?instance.result,
};
