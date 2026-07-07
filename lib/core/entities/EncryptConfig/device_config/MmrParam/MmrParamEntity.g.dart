// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MmrParamEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MmrParamEntity _$MmrParamEntityFromJson(Map<String, dynamic> json) =>
    MmrParamEntity(
      name: json['name'] as String?,
      result: json['result'] == null
          ? null
          : MmrResultEntity.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MmrParamEntityToJson(MmrParamEntity instance) =>
    <String, dynamic>{'name': ?instance.name, 'result': ?instance.result};
