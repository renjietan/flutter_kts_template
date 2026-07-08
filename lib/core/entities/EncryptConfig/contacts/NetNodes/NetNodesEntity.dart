import 'package:json_annotation/json_annotation.dart';

import '../UserItem/UserItemEntity.dart';

part 'NetNodesEntity.g.dart';

@JsonSerializable()
class NetNodesEntity {
  @JsonKey(name: 'NodeId')
  final String? nodeId;

  @JsonKey(name: 'NodeType')
  final int? nodeType;

  @JsonKey(name: 'CodeName')
  final String? codeName;

  @JsonKey(name: 'Users')
  final List<UserItemEntity>? users;

  NetNodesEntity({this.nodeId, this.nodeType, this.codeName, this.users});

  factory NetNodesEntity.fromJson(Map<String, dynamic> json) =>
      _$NetNodesEntityFromJson(json);

  Map<String, dynamic> toJson() => _$NetNodesEntityToJson(this);
}
