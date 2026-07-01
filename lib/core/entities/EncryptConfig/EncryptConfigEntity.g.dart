// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EncryptConfigEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptConfigEntity _$EncryptConfigEntityFromJson(Map<String, dynamic> json) =>
    EncryptConfigEntity(
      keys: (json['key'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, KeyEntity.fromJson(e as Map<String, dynamic>)),
      ),
      radioSubnets: (json['radio_subnet'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, RadioSubnetEntity.fromJson(e as Map<String, dynamic>)),
      ),
      NetNodes: (json['net_node'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          e == null ? null : NetNodeEntity.fromJson(e as Map<String, dynamic>),
        ),
      ),
      deviceConfig: (json['device_config'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, DeviceConfigEntity.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$EncryptConfigEntityToJson(
  EncryptConfigEntity instance,
) => <String, dynamic>{
  'key': ?instance.keys,
  'radio_subnet': ?instance.radioSubnets,
  'device_config': ?instance.deviceConfig,
  'net_node': ?instance.NetNodes,
};
