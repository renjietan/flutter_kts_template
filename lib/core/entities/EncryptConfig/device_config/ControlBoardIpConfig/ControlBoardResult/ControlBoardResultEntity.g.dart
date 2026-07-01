// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ControlBoardResultEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ControlBoardResultEntity _$ControlBoardResultEntityFromJson(
  Map<String, dynamic> json,
) => ControlBoardResultEntity(
  gws: (json['gws'] as List<dynamic>?)
      ?.map(
        (e) => e == null
            ? null
            : RouteGatewayEntity.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  ip1: json['ip1'] as String?,
  ip2: json['ip2'] as String?,
  mask1: json['mask1'] as String?,
  mask2: json['mask2'] as String?,
);

Map<String, dynamic> _$ControlBoardResultEntityToJson(
  ControlBoardResultEntity instance,
) => <String, dynamic>{
  'gws': ?instance.gws,
  'ip1': ?instance.ip1,
  'ip2': ?instance.ip2,
  'mask1': ?instance.mask1,
  'mask2': ?instance.mask2,
};
