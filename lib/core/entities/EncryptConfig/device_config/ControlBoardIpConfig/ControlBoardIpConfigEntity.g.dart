// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ControlBoardIpConfigEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ControlBoardIpConfigEntity _$ControlBoardIpConfigEntityFromJson(
  Map<String, dynamic> json,
) => ControlBoardIpConfigEntity(
  name: json['name'] as String?,
  result: json['result'] == null
      ? null
      : ControlBoardResultEntity.fromJson(
          json['result'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ControlBoardIpConfigEntityToJson(
  ControlBoardIpConfigEntity instance,
) => <String, dynamic>{'name': ?instance.name, 'result': ?instance.result};
