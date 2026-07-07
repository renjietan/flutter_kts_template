import 'package:json_annotation/json_annotation.dart';

part "MmrArrayItemEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class MmrArrayItemEntity {
  final int? id;
  final String? ip;

  MmrArrayItemEntity({this.id, this.ip});

  factory MmrArrayItemEntity.fromJson(Map<String, dynamic> json) =>
      _$MmrArrayItemEntityFromJson(json);
  Map<String, dynamic> toJson() => _$MmrArrayItemEntityToJson(this);
}
