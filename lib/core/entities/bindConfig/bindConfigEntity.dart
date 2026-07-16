import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'bindConfigEntity.g.dart';

@Entity()
@JsonSerializable()
class BindConfigEntity {
  @Id()
  @JsonKey(defaultValue: 0)
  int id;

  String netNodeId;

  String deviceConfigId;

  String keyLoaderId;

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime updatedAt = DateTime.now();

  BindConfigEntity({
    this.id = 0,
    required this.netNodeId,
    required this.deviceConfigId,
    required this.keyLoaderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  factory BindConfigEntity.fromJson(Map<String, dynamic> json) =>
      _$BindConfigEntityFromJson(json);
  // Map<String, dynamic> toJson() => _$UserEntityToJson(this);
  Map<String, dynamic> toJson() {
    final json = _$BindConfigEntityToJson(this);
    return json;
  }
}
