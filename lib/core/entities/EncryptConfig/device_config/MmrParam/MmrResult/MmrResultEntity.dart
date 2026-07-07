import 'package:json_annotation/json_annotation.dart';

import 'MmrArrayItem/MmrArrayItemEntity.dart';

part 'MmrResultEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class MmrResultEntity {
  @JsonKey(name: 'mmrArray')
  final List<MmrArrayItemEntity?>? mmrArray;

  MmrResultEntity({this.mmrArray});

  factory MmrResultEntity.fromJson(Map<String, dynamic> json) =>
      _$MmrResultEntityFromJson(json);
  Map<String, dynamic> toJson() => _$MmrResultEntityToJson(this);
}
