// dap_container.dart
import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/Dap/DapResult/DapResultEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'DapEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class DapEntity {
  final String? name;
  final List<DapResultEntity>? result; // 直接使用具体类型

  DapEntity({this.name, this.result});

  factory DapEntity.fromJson(Map<String, dynamic> json) =>
      _$DapEntityFromJson(json);
  Map<String, dynamic> toJson() => _$DapEntityToJson(this);
}
