// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NetNodeEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetNodeEntity _$NetNodeEntityFromJson(Map<String, dynamic> json) =>
    NetNodeEntity(
      basicInfo: json['BasicInfo'] == null
          ? null
          : BasicInfoEntity.fromJson(json['BasicInfo'] as Map<String, dynamic>),
      file: json['File'] == null
          ? null
          : NetNodeFileEntity.fromJson(json['File'] as Map<String, dynamic>),
      systemConfiguration: json['SystemConfiguration'] == null
          ? null
          : SystemConfigurationEntity.fromJson(
              json['SystemConfiguration'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$NetNodeEntityToJson(NetNodeEntity instance) =>
    <String, dynamic>{
      'BasicInfo': ?instance.basicInfo,
      'File': ?instance.file,
      'SystemConfiguration': ?instance.systemConfiguration,
    };
