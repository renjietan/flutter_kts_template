// 设备类型枚举
enum DeviceType {
  unknown(0, '未知'),
  server(1, '服务端'),
  iec(2, 'IEC'),
  ccu(3, 'CCU'),
  multibandRadio(4, '多波段电台'),
  multibandHandheld(5, '多波段手持台'),
  hf(6, '短波电台'),
  smallHandheld(7, '小型手持台'),
  ccuAudio(8, 'CCU音频');

  final int value;
  final String displayName;
  const DeviceType(this.value, this.displayName);

  static DeviceType fromValue(int v) {
    return DeviceType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => DeviceType.unknown,
    );
  }
}

// 结果枚举
enum Result {
  unspecified(0),
  success(1),
  failed(2);

  final int value;
  const Result(this.value);

  static Result fromValue(int v) {
    return Result.values.firstWhere(
      (e) => e.value == v,
      orElse: () => Result.unspecified,
    );
  }
}

// 解析阶段枚举
enum ParseStage {
  unspecified(0),
  precheck(1),
  receive(2),
  verify(3),
  cacheReuse(4),
  skipped(5);

  final int value;
  const ParseStage(this.value);

  static ParseStage fromValue(int v) {
    return ParseStage.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ParseStage.unspecified,
    );
  }
}

// 传输阶段枚举
enum TransferStage {
  unspecified(0),
  precheck(1),
  receive(2),
  verify(3),
  cacheReuse(4);

  final int value;
  const TransferStage(this.value);

  static TransferStage fromValue(int v) {
    return TransferStage.values.firstWhere(
      (e) => e.value == v,
      orElse: () => TransferStage.unspecified,
    );
  }
}

// 错误码枚举
enum ErrorCode {
  unspecified(0),
  invalidMessage(1),
  invalidPackage(2),
  packageTooLarge(3),
  invalidZipSize(4),
  insufficientStorage(5),
  authAssignmentConflict(6),
  authConflict(7),
  authBindingMissing(8),
  busy(9),
  fileSizeMismatch(10),
  fileHashMismatch(11),
  storageIoError(12),
  parseOutputFailed(13),
  parseTimeout(14),
  outputWriteFailed(15),
  skippedAfterPreviousFailure(16),
  sessionTimeout(17),
  discoveryMismatch(18),
  esnConflict(19),
  authTimeout(20),
  transferSilenceTimeout(21),
  transferNoProgress(22),
  networkInterfaceError(23);

  final int value;
  const ErrorCode(this.value);

  static ErrorCode fromValue(int v) {
    return ErrorCode.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ErrorCode.unspecified,
    );
  }
}

// CPDS 前端活动状态
enum CpdActiveState {
  idle('空闲'),
  discovering('发现中'),
  awaitingDiscoveryConfirmation('等待发现确认'),
  authenticating('认证中'),
  transferring('传输中'),
  waitingParse('等待解析'),
  drainingAfterFailure('失败后清理'),
  completed('已完成'),
  partialSuccess('部分成功'),
  failed('失败');

  final String displayName;
  const CpdActiveState(this.displayName);
}

// 消息类型枚举（对应 Packet 中 oneof body 的字段号）
// Packet 字段: 1=session_id, 2=message_id, 3~14=oneof body
enum CpdMessageType {
  discoverNty(3),
  discoverRsp(4),
  authNty(5),
  authRsp(6),
  transferStartNty(7),
  transferChunkNty(8),
  transferProgressRsp(9),
  transferEndNty(10),
  transferLosspackReq(11),
  transferCompleteRsp(12),
  parseCompleteReq(13),
  parseCompleteAck(14);

  final int fieldNumber;
  const CpdMessageType(this.fieldNumber);

  static CpdMessageType fromFieldNumber(int n) {
    return CpdMessageType.values.firstWhere(
      (e) => e.fieldNumber == n,
      orElse: () => throw ArgumentError('Unknown field number: $n'),
    );
  }
}
