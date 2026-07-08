import 'package:json_annotation/json_annotation.dart';

import 'FileInfo/FileInfoEntity.dart';

part 'UsersEntity.g.dart';

@JsonSerializable()
class UsersEntity {
  @JsonKey(name: 'File')
  final FileInfoEntity? file;

  @JsonKey(name: 'IdNumber')
  final String? idNumber;

  @JsonKey(name: 'Name')
  final String? name;

  @JsonKey(name: 'UserName')
  final String? userName;

  @JsonKey(name: 'CodeName')
  final String? codeName;

  @JsonKey(name: 'Position')
  final String? position;

  @JsonKey(name: 'Superior')
  final List<dynamic>? superior; // 根据JSON为空数组，类型暂用dynamic，可改为List<String>? 但原值为[]，可安全视为List<String>?

  @JsonKey(name: 'HighSuperior')
  final List<String>? highSuperior;

  @JsonKey(name: 'Password')
  final String? password;

  @JsonKey(name: 'Role')
  final String? role;

  @JsonKey(name: 'RoleType')
  final String? roleType;

  UsersEntity({
    this.file,
    this.idNumber,
    this.name,
    this.userName,
    this.codeName,
    this.position,
    this.superior,
    this.highSuperior,
    this.password,
    this.role,
    this.roleType,
  });

  factory UsersEntity.fromJson(Map<String, dynamic> json) =>
      _$UsersEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UsersEntityToJson(this);
}
