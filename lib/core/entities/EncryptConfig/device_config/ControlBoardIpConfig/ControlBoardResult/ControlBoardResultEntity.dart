import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/ControlBoardIpConfig/ControlBoardResult/RouteGateway/RouteGatewayEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part "ControlBoardResultEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class ControlBoardResultEntity {
  final List<RouteGatewayEntity?>? gws;
  final String? ip1;
  final String? ip2;
  final String? mask1;
  final String? mask2;

  ControlBoardResultEntity({
    this.gws,
    this.ip1,
    this.ip2,
    this.mask1,
    this.mask2,
  });

  factory ControlBoardResultEntity.fromJson(Map<String, dynamic> json) =>
      _$ControlBoardResultEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ControlBoardResultEntityToJson(this);
}
