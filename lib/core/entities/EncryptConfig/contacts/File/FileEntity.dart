import 'package:json_annotation/json_annotation.dart';

part 'FileEntity.g.dart';

@JsonSerializable()
class FileEntity {
  @JsonKey(name: 'Layer')
  final String? layer;

  @JsonKey(name: 'Guid')
  final String? guid;

  @JsonKey(name: 'Description')
  final String? description;

  FileEntity({this.layer, this.guid, this.description});

  factory FileEntity.fromJson(Map<String, dynamic> json) =>
      _$FileEntityFromJson(json);

  Map<String, dynamic> toJson() => _$FileEntityToJson(this);
}
