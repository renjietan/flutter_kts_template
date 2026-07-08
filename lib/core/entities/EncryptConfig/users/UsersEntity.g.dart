// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UsersEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsersEntity _$UsersEntityFromJson(Map<String, dynamic> json) => UsersEntity(
  file: json['File'] == null
      ? null
      : FileInfoEntity.fromJson(json['File'] as Map<String, dynamic>),
  idNumber: json['IdNumber'] as String?,
  name: json['Name'] as String?,
  userName: json['UserName'] as String?,
  codeName: json['CodeName'] as String?,
  position: json['Position'] as String?,
  superior: json['Superior'] as List<dynamic>?,
  highSuperior: (json['HighSuperior'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  password: json['Password'] as String?,
  role: json['Role'] as String?,
  roleType: json['RoleType'] as String?,
);

Map<String, dynamic> _$UsersEntityToJson(UsersEntity instance) =>
    <String, dynamic>{
      'File': instance.file,
      'IdNumber': instance.idNumber,
      'Name': instance.name,
      'UserName': instance.userName,
      'CodeName': instance.codeName,
      'Position': instance.position,
      'Superior': instance.superior,
      'HighSuperior': instance.highSuperior,
      'Password': instance.password,
      'Role': instance.role,
      'RoleType': instance.roleType,
    };
