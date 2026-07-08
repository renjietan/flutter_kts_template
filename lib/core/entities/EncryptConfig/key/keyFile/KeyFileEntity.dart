import 'package:json_annotation/json_annotation.dart';

part "KeyFileEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class KeyFileEntity {
  final String? Layer;
  final String? Type;
  final String? Guid;
  final String? Description;

  KeyFileEntity({this.Layer, this.Type, this.Guid, this.Description});

  factory KeyFileEntity.fromJson(Map<String, dynamic> json) =>
      _$KeyFileEntityFromJson(json);
  Map<String, dynamic> toJson() => _$KeyFileEntityToJson(this);
}
