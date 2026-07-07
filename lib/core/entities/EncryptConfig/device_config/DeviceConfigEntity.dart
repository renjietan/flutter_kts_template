import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/ControlBoardIpConfig/ControlBoardIpConfigEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/Dap/DapEntity.dart';
import 'package:flutter_kts_template/core/entities/EncryptConfig/device_config/MmrParam/MmrParamEntity.dart';
import 'package:json_annotation/json_annotation.dart';

import 'AudioBoardIpConfig/AudioBoardIpConfigEntity.dart';
import 'GenericResult/GenericResult.dart';
import 'IPMask/IPMaskEntity.dart';
import 'NtpTimeSyncResult/NtpTimeSyncResult.dart';
import 'TransTableResult/TransTableResultEntity.dart';

part "DeviceConfigEntity.g.dart";

@JsonSerializable(includeIfNull: false)
class DeviceConfigEntity {
  @JsonKey(name: 'audioBoardIpConfig')
  final AudioBoardIpConfigEntity? audioBoardIpConfig;

  @JsonKey(name: 'controlBoardIpConfig')
  final ControlBoardIpConfigEntity? controlBoardIpConfig;

  @JsonKey(name: 'dap')
  final DapEntity? dap;

  @JsonKey(name: 'hfRadio')
  final GenericResult<List<dynamic>?>? hfRadio;

  @JsonKey(name: 'mediaBoardIpConfig')
  final GenericResult<IPMaskEntity?>? mediaBoardIpConfig;

  @JsonKey(name: 'mmrParam')
  final MmrParamEntity? mmrParam;

  @JsonKey(name: 'ntpTimeSync')
  final GenericResult<NtpTimeSyncResult?>? ntpTimeSync;

  @JsonKey(name: 'transTable')
  final TransTableResultEntity? transTable;

  DeviceConfigEntity({
    this.audioBoardIpConfig,
    this.controlBoardIpConfig,
    this.dap,
    this.hfRadio,
    this.mediaBoardIpConfig,
    this.mmrParam,
    this.ntpTimeSync,
    this.transTable,
  });

  factory DeviceConfigEntity.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigEntityFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceConfigEntityToJson(this);
}
