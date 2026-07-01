import 'package:json_annotation/json_annotation.dart';

part "MemberInfoEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class MemberInfoEntity {
  final int? dhcp;
  final String? gateway;
  final String? group;
  final String? ip;
  final int? mac;
  final String? mask;
  final String? name;

  MemberInfoEntity({
    this.dhcp,
    this.gateway,
    this.group,
    this.ip,
    this.mac,
    this.mask,
    this.name,
  });

  factory MemberInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$MemberInfoEntityFromJson(json);
  Map<String, dynamic> toJson() => _$MemberInfoEntityToJson(this);
}
