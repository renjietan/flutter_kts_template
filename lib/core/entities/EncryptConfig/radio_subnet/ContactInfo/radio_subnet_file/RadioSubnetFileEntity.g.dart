// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RadioSubnetFileEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioSubnetFileEntity _$RadioSubnetFileEntityFromJson(
  Map<String, dynamic> json,
) => RadioSubnetFileEntity(
  description: json['Description'] as String?,
  guid: json['Guid'] as String?,
  layer: json['Layer'] as String?,
  waveFormName: json['WaveFormName'] as String?,
  waveFormType: json['WaveFormType'] as String?,
);

Map<String, dynamic> _$RadioSubnetFileEntityToJson(
  RadioSubnetFileEntity instance,
) => <String, dynamic>{
  'Description': ?instance.description,
  'Guid': ?instance.guid,
  'Layer': ?instance.layer,
  'WaveFormName': ?instance.waveFormName,
  'WaveFormType': ?instance.waveFormType,
};
