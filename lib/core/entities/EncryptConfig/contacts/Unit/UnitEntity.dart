import 'package:json_annotation/json_annotation.dart';

part 'UnitEntity.g.dart';

@JsonSerializable()
class UnitEntity {
  @JsonKey(name: 'UnitId')
  final String? unitId;

  @JsonKey(name: 'CodeName')
  final String? codeName;

  UnitEntity({this.unitId, this.codeName});

  factory UnitEntity.fromJson(Map<String, dynamic> json) =>
      _$UnitEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UnitEntityToJson(this);
}
