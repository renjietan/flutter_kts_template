// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RadioSubnetEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioSubnetEntity _$RadioSubnetEntityFromJson(
  Map<String, dynamic> json,
) => RadioSubnetEntity(
  accessMode: json['AccessMode'] as String?,
  contactInfo: json['ContactInfo'] == null
      ? null
      : ContactInfoEntity.fromJson(json['ContactInfo'] as Map<String, dynamic>),
  encryptFlag: (json['EncryptFlag'] as num?)?.toInt(),
  file: json['File'] == null
      ? null
      : RadioSubnetFileEntity.fromJson(json['File'] as Map<String, dynamic>),
  freqNum: RadioSubnetEntity._toIntList(json['FreqNum']),
  masterMac: (json['MasterMac'] as num?)?.toInt(),
  multicastAddress: json['MulticastAddress'] as String?,
  networkID: (json['NetworkID'] as num?)?.toInt(),
  otherInfo: json['OtherInfo'] as Map<String, dynamic>?,
  radiosCnt: (json['RadiosCnt'] as num?)?.toInt(),
  slotTable: (json['SlotTable'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  speed: json['speed'] as String?,
  waveFormID: (json['WaveFormID'] as num?)?.toInt(),
  groups: json['groups'] as Map<String, dynamic>?,
  fhtable: (json['fhtable'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
);

Map<String, dynamic> _$RadioSubnetEntityToJson(RadioSubnetEntity instance) =>
    <String, dynamic>{
      'AccessMode': ?instance.accessMode,
      'ContactInfo': ?instance.contactInfo,
      'EncryptFlag': ?instance.encryptFlag,
      'File': ?instance.file,
      'FreqNum': ?RadioSubnetEntity._toJson(instance.freqNum),
      'MasterMac': ?instance.masterMac,
      'MulticastAddress': ?instance.multicastAddress,
      'NetworkID': ?instance.networkID,
      'OtherInfo': ?instance.otherInfo,
      'RadiosCnt': ?instance.radiosCnt,
      'SlotTable': ?instance.slotTable,
      'speed': ?instance.speed,
      'WaveFormID': ?instance.waveFormID,
      'groups': ?instance.groups,
      'fhtable': ?instance.fhtable,
    };
