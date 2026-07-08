import 'package:flutter_kts_template/core/entities/EncryptConfig/contacts/ContactsEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/DeviceConfigEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/key/KeyEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/net_node/NetNodeEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/radio_subnet/RadioSubnetEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/users/UsersEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'EncryptConfigEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class EncryptConfigEntity {
  @JsonKey(name: 'key')
  final Map<String, KeyEntity>? keys;
  @JsonKey(name: 'radio_subnet')
  final Map<String, RadioSubnetEntity>? radioSubnets;
  @JsonKey(name: 'device_config')
  final Map<String, DeviceConfigEntity>? deviceConfig;
  @JsonKey(name: 'net_node')
  final Map<String, NetNodeEntity?>? NetNodes;
  @JsonKey(name: "users")
  final Map<String, UsersEntity?>? users;
  @JsonKey(name: "contacts")
  final Map<String, ContactsEntity?>? contacts;

  EncryptConfigEntity({
    this.keys,
    this.radioSubnets,
    this.NetNodes,
    this.deviceConfig,
    this.users,
    this.contacts,
  });

  factory EncryptConfigEntity.fromJson(Map<String, dynamic> json) {
    return _$EncryptConfigEntityFromJson(json);
  }
  Map<String, dynamic> toJson() => _$EncryptConfigEntityToJson(this);
}
