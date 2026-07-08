// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ContactsEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactsEntity _$ContactsEntityFromJson(Map<String, dynamic> json) =>
    ContactsEntity(
      file: json['File'] == null
          ? null
          : FileEntity.fromJson(json['File'] as Map<String, dynamic>),
      unitTree: json['UnitTree'] == null
          ? null
          : UnitTreeEntity.fromJson(json['UnitTree'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ContactsEntityToJson(ContactsEntity instance) =>
    <String, dynamic>{'File': instance.file, 'UnitTree': instance.unitTree};
