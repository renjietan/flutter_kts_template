import 'package:json_annotation/json_annotation.dart';

part 'UserItemEntity.g.dart';

@JsonSerializable()
class UserItemEntity {
  @JsonKey(name: 'UserId')
  final String? userId;

  @JsonKey(name: 'CodeName')
  final String? codeName;

  UserItemEntity({this.userId, this.codeName});

  factory UserItemEntity.fromJson(Map<String, dynamic> json) =>
      _$UserItemEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UserItemEntityToJson(this);
}
