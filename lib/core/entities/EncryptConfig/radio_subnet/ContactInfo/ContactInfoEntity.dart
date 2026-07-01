import 'package:json_annotation/json_annotation.dart';

import 'MemberInfo/MemberInfoEntity.dart';

part "ContactInfoEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class ContactInfoEntity {
  @JsonKey(name: 'Members')
  final List<MemberInfoEntity?>? members;

  ContactInfoEntity({this.members});

  factory ContactInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$ContactInfoEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ContactInfoEntityToJson(this);
}
