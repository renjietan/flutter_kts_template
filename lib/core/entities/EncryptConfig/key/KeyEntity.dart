import 'package:json_annotation/json_annotation.dart';

import 'keyFile/KeyFileEntity.dart';

part "KeyEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class KeyEntity {
  @JsonKey(name: 'File')
  final KeyFileEntity? file;

  @JsonKey(name: 'keys')
  final Map<String, String?>? keys;

  KeyEntity({this.file, this.keys});

  factory KeyEntity.fromJson(Map<String, dynamic> json) =>
      _$KeyEntityFromJson(json);
  Map<String, dynamic> toJson() => _$KeyEntityToJson(this);
}
