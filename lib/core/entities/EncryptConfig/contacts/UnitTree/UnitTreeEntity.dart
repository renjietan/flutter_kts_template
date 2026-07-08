import 'package:json_annotation/json_annotation.dart';

import '../../net_node/NetNodeEntity.dart';
import '../Unit/UnitEntity.dart';

part 'UnitTreeEntity.g.dart';

@JsonSerializable()
class UnitTreeEntity {
  @JsonKey(name: 'Unit')
  final UnitEntity? unit;

  @JsonKey(name: 'NetNodes')
  final List<NetNodeEntity>? netNodes;

  // SubUnits 是递归的，直接使用 UnitTreeEntity 自身
  @JsonKey(name: 'SubUnits')
  final List<UnitTreeEntity>? subUnits;

  UnitTreeEntity({this.unit, this.netNodes, this.subUnits});

  factory UnitTreeEntity.fromJson(Map<String, dynamic> json) =>
      _$UnitTreeEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UnitTreeEntityToJson(this);
}
