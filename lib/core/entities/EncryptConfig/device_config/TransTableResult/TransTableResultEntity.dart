import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/transTableResult/transTableGroup/TransTableGroupEntity.dart';
import 'package:json_annotation/json_annotation.dart';

part "TransTableResultEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class TransTableResultEntity {
  @JsonKey(fromJson: _resultFromJson, toJson: _resultToJson)
  final List<TransTableGroupEntity?>? result;

  TransTableResultEntity({this.result});

  factory TransTableResultEntity.fromJson(Map<String, dynamic> json) =>
      _$TransTableResultEntityFromJson(json);
  Map<String, dynamic> toJson() => _$TransTableResultEntityToJson(this);

  static List<TransTableGroupEntity?>? _resultFromJson(dynamic json) {
    if (json == null) return null;
    final list = json as List<dynamic>;
    return list
        .map(
          (e) => e == null
              ? null
              : TransTableGroupEntity.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  static dynamic _resultToJson(List<TransTableGroupEntity?>? value) {
    if (value == null) return null;
    return value.map((e) => e?.toJson()).toList();
  }
}
