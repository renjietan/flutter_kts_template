// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookEntity _$BookEntityFromJson(Map<String, dynamic> json) => BookEntity(
  id: (json['id'] as num?)?.toInt() ?? 0,
  title: json['title'] as String,
)..authorTargetId = (json['authorId'] as num?)?.toInt();

Map<String, dynamic> _$BookEntityToJson(BookEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'authorId': instance.authorTargetId,
    };
