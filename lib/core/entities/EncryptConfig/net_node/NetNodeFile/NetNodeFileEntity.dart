import 'package:json_annotation/json_annotation.dart';

part 'NetNodeFileEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class NetNodeFileEntity {
  final String? description;
  final String? guid;
  final String? layer;
  final String? model;

  NetNodeFileEntity({this.description, this.guid, this.layer, this.model});

  factory NetNodeFileEntity.fromJson(Map<String, dynamic> json) =>
      _$NetNodeFileEntityFromJson(json);
  Map<String, dynamic> toJson() => _$NetNodeFileEntityToJson(this);
}
