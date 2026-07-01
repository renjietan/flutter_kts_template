// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MmrParamEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MmrParamEntity _$MmrParamEntityFromJson(Map<String, dynamic> json) =>
    MmrParamEntity(
      mmrArray: (json['mmrArray'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : MmrArrayItemEntity.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$MmrParamEntityToJson(MmrParamEntity instance) =>
    <String, dynamic>{'mmrArray': ?instance.mmrArray};
