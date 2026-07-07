// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MmrResultEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MmrResultEntity _$MmrResultEntityFromJson(Map<String, dynamic> json) =>
    MmrResultEntity(
      mmrArray: (json['mmrArray'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : MmrArrayItemEntity.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$MmrResultEntityToJson(MmrResultEntity instance) =>
    <String, dynamic>{'mmrArray': ?instance.mmrArray};
