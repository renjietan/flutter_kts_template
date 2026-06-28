import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

import '../book/bookEntity.dart';

part 'userEntity.g.dart'; // JsonSerializable: 序列化的关键

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable(explicitToJson: true)
@Entity()
class UserEntity {
  @Id()
  int id;

  String name;

  int age;

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @Backlink('author') // 只想 book 表的 author 字段
  @JsonKey(ignore: true) // 忽略: 防止 json 序列化失败
  final ToMany<BookEntity> books = ToMany<BookEntity>();

  UserEntity({
    this.id = 0,
    this.name = "",
    this.age = 0,
    required this.updatedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
  // Map<String, dynamic> toJson() => _$UserEntityToJson(this);
  Map<String, dynamic> toJson() {
    final json = _$UserEntityToJson(this);
    // 手动添加 books，每个 book 的 toJson 只包含 authorId，不会循环
    json['books'] = books.map((b) => b.toJson()).toList();
    return json;
  }
}
