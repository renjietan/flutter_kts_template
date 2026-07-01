import 'package:json_annotation/json_annotation.dart';

part "KeyFileEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class KeyFileEntity {
  final String? layer;
  final String? type;
  final int? guid;
  final int? description;

  KeyFileEntity({this.layer, this.type, this.guid, this.description});

  factory KeyFileEntity.fromJson(Map<String, dynamic> json) =>
      _$KeyFileEntityFromJson(json);
  Map<String, dynamic> toJson() => _$KeyFileEntityToJson(this);
}
