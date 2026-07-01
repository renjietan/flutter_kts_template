// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SystemConfigurationEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemConfigurationEntity _$SystemConfigurationEntityFromJson(
  Map<String, dynamic> json,
) => SystemConfigurationEntity(
  lanMember: (json['LANMember'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>?)?.map((e) => e as String).toList()),
  ),
  lanPrimary: (json['LANPrimary'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>?)?.map((e) => e as String).toList()),
  ),
  radio: (json['radio'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>?)?.map((e) => e as String).toList()),
  ),
  starLink: json['StarLink'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SystemConfigurationEntityToJson(
  SystemConfigurationEntity instance,
) => <String, dynamic>{
  'LANMember': ?instance.lanMember,
  'LANPrimary': ?instance.lanPrimary,
  'radio': ?instance.radio,
  'StarLink': ?instance.starLink,
};
