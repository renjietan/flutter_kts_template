// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NetNodesEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetNodesEntity _$NetNodesEntityFromJson(Map<String, dynamic> json) =>
    NetNodesEntity(
      nodeId: json['NodeId'] as String?,
      nodeType: (json['NodeType'] as num?)?.toInt(),
      codeName: json['CodeName'] as String?,
      users: (json['Users'] as List<dynamic>?)
          ?.map((e) => UserItemEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NetNodesEntityToJson(NetNodesEntity instance) =>
    <String, dynamic>{
      'NodeId': instance.nodeId,
      'NodeType': instance.nodeType,
      'CodeName': instance.codeName,
      'Users': instance.users,
    };
