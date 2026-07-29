import 'package:flutter_kts_template/objectbox.g.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'keyLoaderDetailsEntity.g.dart';

@Entity()
@JsonSerializable()
class KeyLoaderDetailsEntity {
  @Id()
  @JsonKey(defaultValue: 0)
  int id;

  String netNodePackageName; // 4_net_node 中的文件名称

  String dcPackageName; // 3_device_config 中的文件名称

  String? location; // 位置

  String? SN; // 电台SN号

  int? radioId; // 绑定的电台

  String? consumer; // 使用人

  int keyLoaderId;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt = DateTime.now();

  KeyLoaderDetailsEntity({
    this.id = 0,
    required this.netNodePackageName,
    required this.dcPackageName,
    required this.keyLoaderId,
    this.radioId,
    this.consumer,
    this.location,
    this.SN,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory KeyLoaderDetailsEntity.fromJson(Map<String, dynamic> json) =>
      _$KeyLoaderDetailsEntityFromJson(json);
  Map<String, dynamic> toJson() {
    final json = _$KeyLoaderDetailsEntityToJson(this);
    return json;
  }
}
