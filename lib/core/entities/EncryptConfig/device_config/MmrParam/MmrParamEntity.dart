import 'package:json_annotation/json_annotation.dart';

import 'MmrArrayItem/MmrArrayItemEntity.dart';

part "MmrParamEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class MmrParamEntity {
  @JsonKey(name: 'mmrArray')
  final List<MmrArrayItemEntity?>? mmrArray;

  MmrParamEntity({this.mmrArray});

  factory MmrParamEntity.fromJson(Map<String, dynamic> json) =>
      _$MmrParamEntityFromJson(json);
  Map<String, dynamic> toJson() => _$MmrParamEntityToJson(this);
}
