// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'KeyFileEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyFileEntity _$KeyFileEntityFromJson(Map<String, dynamic> json) =>
    KeyFileEntity(
      Layer: json['Layer'] as String?,
      Type: json['Type'] as String?,
      Guid: json['Guid'] as String?,
      Description: json['Description'] as String?,
    );

Map<String, dynamic> _$KeyFileEntityToJson(KeyFileEntity instance) =>
    <String, dynamic>{
      'Layer': ?instance.Layer,
      'Type': ?instance.Type,
      'Guid': ?instance.Guid,
      'Description': ?instance.Description,
    };
