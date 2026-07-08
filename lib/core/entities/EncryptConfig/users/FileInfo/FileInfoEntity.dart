import 'package:json_annotation/json_annotation.dart';

part 'FileInfoEntity.g.dart';

@JsonSerializable()
class FileInfoEntity {
  @JsonKey(name: 'Layer')
  final String? layer;

  @JsonKey(name: 'Guid')
  final String? guid;

  FileInfoEntity({this.layer, this.guid});

  factory FileInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$FileInfoEntityFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoEntityToJson(this);
}
