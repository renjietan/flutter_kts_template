// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TransTableEntry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransTableEntry _$TransTableEntryFromJson(Map<String, dynamic> json) =>
    TransTableEntry(
      dstNum: (json['dstNum'] as num?)?.toInt(),
      dstReserve: (json['dstReserve'] as num?)?.toInt(),
      dstSlfCode: json['dstSlfCode'] as String?,
      dstType: (json['dstType'] as num?)?.toInt(),
      index: (json['index'] as num?)?.toInt(),
      srcNum: json['srcNum'] as String?,
      srcReserve: (json['srcReserve'] as num?)?.toInt(),
      srcType: (json['srcType'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TransTableEntryToJson(TransTableEntry instance) =>
    <String, dynamic>{
      'dstNum': ?instance.dstNum,
      'dstReserve': ?instance.dstReserve,
      'dstSlfCode': ?instance.dstSlfCode,
      'dstType': ?instance.dstType,
      'index': ?instance.index,
      'srcNum': ?instance.srcNum,
      'srcReserve': ?instance.srcReserve,
      'srcType': ?instance.srcType,
    };
