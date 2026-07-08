// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UnitTreeEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitTreeEntity _$UnitTreeEntityFromJson(Map<String, dynamic> json) =>
    UnitTreeEntity(
      unit: json['Unit'] == null
          ? null
          : UnitEntity.fromJson(json['Unit'] as Map<String, dynamic>),
      netNodes: (json['NetNodes'] as List<dynamic>?)
          ?.map((e) => NetNodeEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      subUnits: (json['SubUnits'] as List<dynamic>?)
          ?.map((e) => UnitTreeEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UnitTreeEntityToJson(UnitTreeEntity instance) =>
    <String, dynamic>{
      'Unit': instance.unit,
      'NetNodes': instance.netNodes,
      'SubUnits': instance.subUnits,
    };
