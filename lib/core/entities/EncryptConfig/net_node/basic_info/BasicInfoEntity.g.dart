// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BasicInfoEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BasicInfoEntity _$BasicInfoEntityFromJson(Map<String, dynamic> json) =>
    BasicInfoEntity(
      networkSegment: json['NetworkSegment'] as String?,
      nodeName: json['NodeName'] as String?,
      nodeType: (json['NodeType'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BasicInfoEntityToJson(BasicInfoEntity instance) =>
    <String, dynamic>{
      'NetworkSegment': ?instance.networkSegment,
      'NodeName': ?instance.nodeName,
      'NodeType': ?instance.nodeType,
    };
