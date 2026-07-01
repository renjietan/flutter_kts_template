import 'package:json_annotation/json_annotation.dart';

import '../IPMask/IPMaskEntity.dart';

part "AudioBoardIpConfigEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class AudioBoardIpConfigEntity {
  final String? name;
  final IPMaskEntity? result;

  AudioBoardIpConfigEntity({this.name, this.result});

  factory AudioBoardIpConfigEntity.fromJson(Map<String, dynamic> json) =>
      _$AudioBoardIpConfigEntityFromJson(json);
  Map<String, dynamic> toJson() => _$AudioBoardIpConfigEntityToJson(this);
}
