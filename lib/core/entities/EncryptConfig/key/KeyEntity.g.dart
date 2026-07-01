// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'KeyEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyEntity _$KeyEntityFromJson(Map<String, dynamic> json) => KeyEntity(
  file: json['File'] == null
      ? null
      : KeyFileEntity.fromJson(json['File'] as Map<String, dynamic>),
  keys: (json['keys'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String?),
  ),
);

Map<String, dynamic> _$KeyEntityToJson(KeyEntity instance) => <String, dynamic>{
  'File': ?instance.file,
  'keys': ?instance.keys,
};
