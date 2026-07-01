import 'package:json_annotation/json_annotation.dart';

part 'TransTableEntry.g.dart';

@JsonSerializable(includeIfNull: false)
class TransTableEntry {
  @JsonKey(name: 'dstNum')
  final String? dstNum;

  @JsonKey(name: 'dstReserve')
  final String? dstReserve;

  @JsonKey(name: 'dstSlfCode')
  final String? dstSlfCode;

  @JsonKey(name: 'dstType')
  final int? dstType;

  final int? index;

  @JsonKey(name: 'srcNum')
  final String? srcNum;

  @JsonKey(name: 'srcReserve')
  final int? srcReserve;

  @JsonKey(name: 'srcType')
  final int? srcType;

  TransTableEntry({
    this.dstNum,
    this.dstReserve,
    this.dstSlfCode,
    this.dstType,
    this.index,
    this.srcNum,
    this.srcReserve,
    this.srcType,
  });

  factory TransTableEntry.fromJson(Map<String, dynamic> json) =>
      _$TransTableEntryFromJson(json);
  Map<String, dynamic> toJson() => _$TransTableEntryToJson(this);
}
