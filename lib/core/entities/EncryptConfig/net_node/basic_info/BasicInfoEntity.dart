import 'package:json_annotation/json_annotation.dart';

part 'BasicInfoEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class BasicInfoEntity {
  @JsonKey(name: 'NetworkSegment')
  final String? networkSegment;

  @JsonKey(name: 'NodeName')
  final String? nodeName;

  @JsonKey(name: 'NodeType')
  final int? nodeType;

  BasicInfoEntity({this.networkSegment, this.nodeName, this.nodeType});

  factory BasicInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$BasicInfoEntityFromJson(json);
  Map<String, dynamic> toJson() => _$BasicInfoEntityToJson(this);
}
