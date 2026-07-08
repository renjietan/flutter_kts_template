import 'package:flutter_kts_template/core/entities/EncryptConfig/radio_subnet/ContactInfo/radio_subnet_file/RadioSubnetFileEntity.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ContactInfo/ContactInfoEntity.dart';

part "RadioSubnetEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class RadioSubnetEntity {
  @JsonKey(name: 'AccessMode')
  final String? accessMode;

  @JsonKey(name: 'ContactInfo')
  final ContactInfoEntity? contactInfo;

  @JsonKey(name: 'EncryptFlag')
  final int? encryptFlag;

  @JsonKey(name: 'File')
  final RadioSubnetFileEntity? file;

  @JsonKey(name: 'FreqNum', fromJson: _toIntList, toJson: _toJson)
  final List<num>? freqNum;

  @JsonKey(name: 'MasterMac')
  final int? masterMac;

  @JsonKey(name: 'MulticastAddress')
  final String? multicastAddress;

  @JsonKey(name: 'NetworkID')
  final int? networkID;

  @JsonKey(name: 'OtherInfo')
  final Map<String, dynamic>? otherInfo;

  @JsonKey(name: 'RadiosCnt')
  final int? radiosCnt;

  @JsonKey(name: 'SlotTable')
  final List<int>? slotTable;

  final String? speed;

  @JsonKey(name: 'WaveFormID')
  final int? waveFormID;

  final Map<String, dynamic>? groups;
  final List<double>? fhtable; // 注意：浮点频率列表

  RadioSubnetEntity({
    this.accessMode,
    this.contactInfo,
    this.encryptFlag,
    this.file,
    this.freqNum,
    this.masterMac,
    this.multicastAddress,
    this.networkID,
    this.otherInfo,
    this.radiosCnt,
    this.slotTable,
    this.speed,
    this.waveFormID,
    this.groups,
    this.fhtable,
  });

  factory RadioSubnetEntity.fromJson(Map<String, dynamic> json) =>
      _$RadioSubnetEntityFromJson(json);
  Map<String, dynamic> toJson() => _$RadioSubnetEntityToJson(this);

  static List<num>? _toIntList(dynamic json) {
    if (json == null) return null;
    if (json is int) return [json]; // 单个数字 -> 变成单元素列表
    if (json is double) return [json];
    if (json is List) {
      return json.map((e) => e as int).toList();
    }
    throw FormatException('RadioSubnetEntity: 无法解析 data 字段，期望 int 或 List<int>');
  }

  // 自定义序列化（转回 JSON 时，依然输出数组，保持一致性）
  static dynamic _toJson(List<num>? list) => list;
}
