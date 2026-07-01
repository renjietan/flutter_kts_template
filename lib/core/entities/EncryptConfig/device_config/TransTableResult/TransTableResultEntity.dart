import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/transTableResult/transTableGroup/TransTableGroupEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part "TransTableResultEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class TransTableResultEntity {
  final List<TransTableGroupEntity?>? result;

  TransTableResultEntity({this.result});

  factory TransTableResultEntity.fromJson(Map<String, dynamic> json) =>
      _$TransTableResultEntityFromJson(json);
  Map<String, dynamic> toJson() => _$TransTableResultEntityToJson(this);
}
