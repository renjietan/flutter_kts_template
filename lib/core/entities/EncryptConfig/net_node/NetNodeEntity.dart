import 'package:flutter_kts_template/core/entities/EncryptConfig/net_node/NetNodeFile/NetNodeFileEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/net_node/SystemConfiguration/SystemConfigurationEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/net_node/basic_info/BasicInfoEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'NetNodeEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class NetNodeEntity {
  @JsonKey(name: 'BasicInfo')
  final BasicInfoEntity? basicInfo;

  @JsonKey(name: 'File')
  final NetNodeFileEntity? file;

  @JsonKey(name: 'SystemConfiguration')
  final SystemConfigurationEntity? systemConfiguration;

  NetNodeEntity({this.basicInfo, this.file, this.systemConfiguration});

  factory NetNodeEntity.fromJson(Map<String, dynamic> json) =>
      _$NetNodeEntityFromJson(json);
  Map<String, dynamic> toJson() => _$NetNodeEntityToJson(this);
}
