// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MemberInfoEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberInfoEntity _$MemberInfoEntityFromJson(Map<String, dynamic> json) =>
    MemberInfoEntity(
      dhcp: (json['dhcp'] as num?)?.toInt(),
      gateway: json['gateway'] as String?,
      group: json['group'] as String?,
      ip: json['ip'] as String?,
      mac: (json['mac'] as num?)?.toInt(),
      mask: json['mask'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$MemberInfoEntityToJson(MemberInfoEntity instance) =>
    <String, dynamic>{
      'dhcp': ?instance.dhcp,
      'gateway': ?instance.gateway,
      'group': ?instance.group,
      'ip': ?instance.ip,
      'mac': ?instance.mac,
      'mask': ?instance.mask,
      'name': ?instance.name,
    };
