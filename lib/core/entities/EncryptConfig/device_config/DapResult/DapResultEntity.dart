import 'package:json_annotation/json_annotation.dart';

part "DapResultEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class DapResultEntity {
  @JsonKey(name: 'dapUid')
  final int? dapUid;
  final String? name;

  DapResultEntity({this.dapUid, this.name});

  factory DapResultEntity.fromJson(Map<String, dynamic> json) =>
      _$DapResultEntityFromJson(json);
  Map<String, dynamic> toJson() => _$DapResultEntityToJson(this);
}
