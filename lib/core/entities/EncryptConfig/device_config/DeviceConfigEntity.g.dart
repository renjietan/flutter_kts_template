// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DeviceConfigEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceConfigEntity _$DeviceConfigEntityFromJson(Map<String, dynamic> json) =>
    DeviceConfigEntity(
      audioBoardIpConfig: json['audioBoardIpConfig'] == null
          ? null
          : AudioBoardIpConfigEntity.fromJson(
              json['audioBoardIpConfig'] as Map<String, dynamic>,
            ),
      controlBoardIpConfig: json['controlBoardIpConfig'] == null
          ? null
          : ControlBoardIpConfigEntity.fromJson(
              json['controlBoardIpConfig'] as Map<String, dynamic>,
            ),
      dap: json['dap'] == null
          ? null
          : DapEntity.fromJson(json['dap'] as Map<String, dynamic>),
      hfRadio: json['hfRadio'] == null
          ? null
          : GenericResult<List<dynamic>?>.fromJson(
              json['hfRadio'] as Map<String, dynamic>,
              (value) => value as List<dynamic>?,
            ),
      mediaBoardIpConfig: json['mediaBoardIpConfig'] == null
          ? null
          : GenericResult<IPMaskEntity?>.fromJson(
              json['mediaBoardIpConfig'] as Map<String, dynamic>,
              (value) => value == null
                  ? null
                  : IPMaskEntity.fromJson(value as Map<String, dynamic>),
            ),
      mmrParam: json['mmrParam'] == null
          ? null
          : MmrParamEntity.fromJson(json['mmrParam'] as Map<String, dynamic>),
      ntpTimeSync: json['ntpTimeSync'] == null
          ? null
          : GenericResult<NtpTimeSyncResult?>.fromJson(
              json['ntpTimeSync'] as Map<String, dynamic>,
              (value) => value == null
                  ? null
                  : NtpTimeSyncResult.fromJson(value as Map<String, dynamic>),
            ),
      transTable: json['transTable'] == null
          ? null
          : TransTableResultEntity.fromJson(
              json['transTable'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$DeviceConfigEntityToJson(
  DeviceConfigEntity instance,
) => <String, dynamic>{
  'audioBoardIpConfig': ?instance.audioBoardIpConfig,
  'controlBoardIpConfig': ?instance.controlBoardIpConfig,
  'dap': ?instance.dap,
  'hfRadio': ?instance.hfRadio?.toJson((value) => value),
  'mediaBoardIpConfig': ?instance.mediaBoardIpConfig?.toJson((value) => value),
  'mmrParam': ?instance.mmrParam,
  'ntpTimeSync': ?instance.ntpTimeSync?.toJson((value) => value),
  'transTable': ?instance.transTable,
};
