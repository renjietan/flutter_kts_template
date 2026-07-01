import 'package:json_annotation/json_annotation.dart';

part 'IPMaskEntity.g.dart';

@JsonSerializable(includeIfNull: false)
class IPMaskEntity {
  final String? ip;
  final String? mask;

  IPMaskEntity({this.ip, this.mask});

  factory IPMaskEntity.fromJson(Map<String, dynamic> json) =>
      _$IPMaskEntityFromJson(json);
  Map<String, dynamic> toJson() => _$IPMaskEntityToJson(this);
}
