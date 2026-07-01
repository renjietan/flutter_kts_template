// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TransTableResultEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransTableResultEntity _$TransTableResultEntityFromJson(
  Map<String, dynamic> json,
) => TransTableResultEntity(
  result: (json['result'] as List<dynamic>?)
      ?.map(
        (e) => e == null
            ? null
            : TransTableGroupEntity.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$TransTableResultEntityToJson(
  TransTableResultEntity instance,
) => <String, dynamic>{'result': ?instance.result};
