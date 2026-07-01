import 'package:json_annotation/json_annotation.dart';

part "RadioSubnetFileEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class RadioSubnetFileEntity {
  @JsonKey(name: 'Description')
  final String? description;

  @JsonKey(name: 'Guid')
  final String? guid;

  @JsonKey(name: 'Layer')
  final String? layer;

  @JsonKey(name: 'WaveFormName')
  final String? waveFormName;

  @JsonKey(name: 'WaveFormType')
  final String? waveFormType;

  RadioSubnetFileEntity({
    this.description,
    this.guid,
    this.layer,
    this.waveFormName,
    this.waveFormType,
  });

  factory RadioSubnetFileEntity.fromJson(Map<String, dynamic> json) =>
      _$RadioSubnetFileEntityFromJson(json);
  Map<String, dynamic> toJson() => _$RadioSubnetFileEntityToJson(this);
}
