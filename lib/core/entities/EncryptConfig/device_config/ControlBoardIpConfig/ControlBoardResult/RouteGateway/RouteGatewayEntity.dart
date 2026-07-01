import 'package:json_annotation/json_annotation.dart';

part "RouteGatewayEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class RouteGatewayEntity {
  @JsonKey(name: 'isRouteAddGw')
  final int? isRouteAddGw;

  @JsonKey(name: 'routeDev')
  final int? routeDev;

  @JsonKey(name: 'routeDstIP')
  final String? routeDstIP;

  @JsonKey(name: 'routeGw')
  final String? routeGw;

  @JsonKey(name: 'routeMask')
  final String? routeMask;

  RouteGatewayEntity({
    this.isRouteAddGw,
    this.routeDev,
    this.routeDstIP,
    this.routeGw,
    this.routeMask,
  });

  factory RouteGatewayEntity.fromJson(Map<String, dynamic> json) =>
      _$RouteGatewayEntityFromJson(json);
  Map<String, dynamic> toJson() => _$RouteGatewayEntityToJson(this);
}
