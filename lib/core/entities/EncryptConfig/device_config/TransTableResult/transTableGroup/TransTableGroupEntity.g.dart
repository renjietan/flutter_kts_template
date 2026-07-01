// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TransTableGroupEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransTableGroupEntity _$TransTableGroupEntityFromJson(
  Map<String, dynamic> json,
) => TransTableGroupEntity(
  table: (json['table'] as List<dynamic>?)
      ?.map(
        (e) => e == null
            ? null
            : TransTableEntry.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  type: (json['type'] as num?)?.toInt(),
);

Map<String, dynamic> _$TransTableGroupEntityToJson(
  TransTableGroupEntity instance,
) => <String, dynamic>{'table': ?instance.table, 'type': ?instance.type};
