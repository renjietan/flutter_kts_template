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

  @JsonKey(name: 'FreqNum')
  final int? freqNum;

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
}
