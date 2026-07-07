// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MmrArrayItemEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MmrArrayItemEntity _$MmrArrayItemEntityFromJson(Map<String, dynamic> json) =>
    MmrArrayItemEntity(
      id: (json['id'] as num?)?.toInt(),
      ip: json['ip'] as String?,
    );

Map<String, dynamic> _$MmrArrayItemEntityToJson(MmrArrayItemEntity instance) =>
    <String, dynamic>{'id': ?instance.id, 'ip': ?instance.ip};
