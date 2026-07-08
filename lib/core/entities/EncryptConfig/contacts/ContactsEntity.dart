import 'package:json_annotation/json_annotation.dart';

import 'File/FileEntity.dart';
import 'UnitTree/UnitTreeEntity.dart';

part 'ContactsEntity.g.dart';

@JsonSerializable()
class ContactsEntity {
  @JsonKey(name: 'File')
  final FileEntity? file;

  @JsonKey(name: 'UnitTree')
  final UnitTreeEntity? unitTree;

  ContactsEntity({this.file, this.unitTree});

  factory ContactsEntity.fromJson(Map<String, dynamic> json) =>
      _$ContactsEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ContactsEntityToJson(this);
}
