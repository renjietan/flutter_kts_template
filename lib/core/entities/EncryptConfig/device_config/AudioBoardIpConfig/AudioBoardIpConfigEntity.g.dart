// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AudioBoardIpConfigEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioBoardIpConfigEntity _$AudioBoardIpConfigEntityFromJson(
  Map<String, dynamic> json,
) => AudioBoardIpConfigEntity(
  name: json['name'] as String?,
  result: json['result'] == null
      ? null
      : IPMaskEntity.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AudioBoardIpConfigEntityToJson(
  AudioBoardIpConfigEntity instance,
) => <String, dynamic>{'name': ?instance.name, 'result': ?instance.result};
