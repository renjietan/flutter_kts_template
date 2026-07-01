import 'package:json_annotation/json_annotation.dart';

import 'TransTableEntry/TransTableEntry.dart';

part "TransTableGroupEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class TransTableGroupEntity {
  final List<TransTableEntry?>? table;
  final int? type;

  TransTableGroupEntity({this.table, this.type});

  factory TransTableGroupEntity.fromJson(Map<String, dynamic> json) =>
      _$TransTableGroupEntityFromJson(json);
  Map<String, dynamic> toJson() => _$TransTableGroupEntityToJson(this);
}
