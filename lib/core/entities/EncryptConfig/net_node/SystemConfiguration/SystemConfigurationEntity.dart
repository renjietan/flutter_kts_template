import 'package:json_annotation/json_annotation.dart';

part 'SystemConfigurationEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class SystemConfigurationEntity {
  @JsonKey(name: 'LANMember')
  final Map<String, List<String>?>? lanMember;

  @JsonKey(name: 'LANPrimary')
  final Map<String, List<String>?>? lanPrimary;

  final Map<String, List<String>?>? radio;

  @JsonKey(name: 'StarLink')
  final Map<String, dynamic>? starLink;

  SystemConfigurationEntity({
    this.lanMember,
    this.lanPrimary,
    this.radio,
    this.starLink,
  });

  factory SystemConfigurationEntity.fromJson(Map<String, dynamic> json) =>
      _$SystemConfigurationEntityFromJson(json);
  Map<String, dynamic> toJson() => _$SystemConfigurationEntityToJson(this);
}
