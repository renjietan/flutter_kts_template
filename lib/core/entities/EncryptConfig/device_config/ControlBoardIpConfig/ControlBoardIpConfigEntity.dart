import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/ControlBoardIpConfig/ControlBoardResult/ControlBoardResultEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part "ControlBoardIpConfigEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class ControlBoardIpConfigEntity {
  final String? name;
  final ControlBoardResultEntity? result;

  ControlBoardIpConfigEntity({this.name, this.result});

  factory ControlBoardIpConfigEntity.fromJson(Map<String, dynamic> json) =>
      _$ControlBoardIpConfigEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ControlBoardIpConfigEntityToJson(this);
}
