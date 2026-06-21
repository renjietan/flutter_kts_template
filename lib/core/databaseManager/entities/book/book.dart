import 'package:flutter_kts_template/core/databaseManager/entities/user/user.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'book.g.dart';

@Entity()
@JsonSerializable(explicitToJson: true)
class BookEntity {
  @Id()
  int id;

  String title;

  @JsonKey(ignore: true) // 重要：忽略 ToOne 对象本身
  final author = ToOne<UserEntity>();

  // 使用不同的名称，避免与自动生成的 authorId 冲突
  @JsonKey(name: 'authorId') // JSON 中仍然输出为 "authorId"
  int? get authorTargetId => author.targetId;

  set authorTargetId(int? id) {
    if (id != null) {
      author.targetId = id;
    }
  }

  BookEntity({this.id = 0, required this.title});

  factory BookEntity.fromJson(Map<String, dynamic> json) =>
      _$BookEntityFromJson(json);
  Map<String, dynamic> toJson() => _$BookEntityToJson(this);
}
