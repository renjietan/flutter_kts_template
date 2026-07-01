// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NtpTimeSyncResult.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NtpTimeSyncResult _$NtpTimeSyncResultFromJson(Map<String, dynamic> json) =>
    NtpTimeSyncResult(
      ifOpen: (json['ifOpen'] as num?)?.toInt(),
      interval: (json['interval'] as num?)?.toInt(),
      ip: json['ip'] as String?,
    );

Map<String, dynamic> _$NtpTimeSyncResultToJson(NtpTimeSyncResult instance) =>
    <String, dynamic>{
      'ifOpen': ?instance.ifOpen,
      'interval': ?instance.interval,
      'ip': ?instance.ip,
    };
