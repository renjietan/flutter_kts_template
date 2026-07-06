import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'keyLoadersEntity.g.dart';

@Entity()
@JsonSerializable()
class KeyLoadersEntity {
  @Id()
  @JsonKey(defaultValue: 0)
  int id;

  String name;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt = DateTime.now();

  KeyLoadersEntity({
    this.id = 0,
    required this.name,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory KeyLoadersEntity.fromJson(Map<String, dynamic> json) =>
      _$KeyLoadersEntityFromJson(json);
  // Map<String, dynamic> toJson() => _$UserEntityToJson(this);
  Map<String, dynamic> toJson() {
    final json = _$KeyLoadersEntityToJson(this);
    return json;
  }
}
