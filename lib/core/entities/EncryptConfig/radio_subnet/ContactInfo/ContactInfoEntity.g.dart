// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ContactInfoEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactInfoEntity _$ContactInfoEntityFromJson(Map<String, dynamic> json) =>
    ContactInfoEntity(
      members: (json['Members'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : MemberInfoEntity.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$ContactInfoEntityToJson(ContactInfoEntity instance) =>
    <String, dynamic>{'Members': ?instance.members};
