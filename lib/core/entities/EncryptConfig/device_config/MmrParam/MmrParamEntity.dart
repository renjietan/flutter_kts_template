import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/MmrParam/MmrResult/MmrResultEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'MmrParamEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class MmrParamEntity {
  final String? name;
  final MmrResultEntity? result; // 直接使用具体类型，无需泛型

  MmrParamEntity({this.name, this.result});

  factory MmrParamEntity.fromJson(Map<String, dynamic> json) =>
      _$MmrParamEntityFromJson(json);
  Map<String, dynamic> toJson() => _$MmrParamEntityToJson(this);
}
