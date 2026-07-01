import 'package:json_annotation/json_annotation.dart';

part "NtpTimeSyncResult.g.dart";

@JsonSerializable(includeIfNull: false)
class NtpTimeSyncResult {
  @JsonKey(name: 'ifOpen')
  final int? ifOpen;
  final int? interval;
  final String? ip;

  NtpTimeSyncResult({this.ifOpen, this.interval, this.ip});

  factory NtpTimeSyncResult.fromJson(Map<String, dynamic> json) =>
      _$NtpTimeSyncResultFromJson(json);
  Map<String, dynamic> toJson() => _$NtpTimeSyncResultToJson(this);
}
