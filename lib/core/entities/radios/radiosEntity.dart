import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'radiosEntity.g.dart'; // JsonSerializable: 序列化的关键

@Entity()
@JsonSerializable()
class RadiosEntity {
  @Id()
  int id;

  String alias;

  String consumer;

  String location;

  String sn;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt = DateTime.now();

  RadiosEntity({
    this.id = 0,
    required this.consumer,
    required this.location,
    required this.sn,
    required this.alias,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory RadiosEntity.fromJson(Map<String, dynamic> json) =>
      _$RadiosEntityFromJson(json);
  // Map<String, dynamic> toJson() => _$UserEntityToJson(this);
  Map<String, dynamic> toJson() {
    final json = _$RadiosEntityToJson(this);
    return json;
  }
}
