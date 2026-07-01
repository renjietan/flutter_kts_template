// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RouteGatewayEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteGatewayEntity _$RouteGatewayEntityFromJson(Map<String, dynamic> json) =>
    RouteGatewayEntity(
      isRouteAddGw: (json['isRouteAddGw'] as num?)?.toInt(),
      routeDev: (json['routeDev'] as num?)?.toInt(),
      routeDstIP: json['routeDstIP'] as String?,
      routeGw: json['routeGw'] as String?,
      routeMask: json['routeMask'] as String?,
    );

Map<String, dynamic> _$RouteGatewayEntityToJson(RouteGatewayEntity instance) =>
    <String, dynamic>{
      'isRouteAddGw': ?instance.isRouteAddGw,
      'routeDev': ?instance.routeDev,
      'routeDstIP': ?instance.routeDstIP,
      'routeGw': ?instance.routeGw,
      'routeMask': ?instance.routeMask,
    };
