import 'dart:typed_data';

import 'cpd_enums.dart';

// 客户端身份
class ClientIdentity {
  final String esn;
  final List<String> deviceTypes;

  const ClientIdentity({
    required this.esn,
    required this.deviceTypes,
  });

  Map<String, dynamic> toJson() => {
    'esn': esn,
    'deviceTypes': deviceTypes,
  };
}

// 认证分配
class AuthAssignment {
  final DeviceType deviceType;
  final String esn;
  final String nodeId;
  final String deviceId;

  const AuthAssignment({
    required this.deviceType,
    required this.esn,
    required this.nodeId,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'deviceType': deviceType.name,
    'esn': esn,
    'nodeId': nodeId,
    'deviceId': deviceId,
  };
}

// 认证绑定
class AuthBinding {
  final DeviceType deviceType;
  final String nodeId;
  final String deviceId;

  const AuthBinding({
    required this.deviceType,
    required this.nodeId,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'deviceType': deviceType.name,
    'nodeId': nodeId,
    'deviceId': deviceId,
  };
}

// 发现结果
class DiscoverResult {
  final String esn;
  final Uint8List instanceNonce;
  final List<String> deviceTypes;
  final String currentIp;
  final String subnetMask;

  const DiscoverResult({
    required this.esn,
    required this.instanceNonce,
    required this.deviceTypes,
    required this.currentIp,
    required this.subnetMask,
  });

  String get esnSuffix => esn.length >= 6 ? esn.substring(esn.length - 6) : esn;

  // 去重键: esn + instance_nonce
  String get dedupKey => '${esn}_${_bytesToHex(instanceNonce)}';

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

// 缺包区间
class MissingRange {
  final int start;
  final int end;

  const MissingRange({required this.start, required this.end});

  int get length => end - start + 1;

  bool contains(int index) => index >= start && index <= end;

  static List<MissingRange> merge(List<MissingRange> ranges) {
    if (ranges.isEmpty) return [];
    final sorted = List<MissingRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));
    final merged = <MissingRange>[];
    var current = sorted.first;
    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      if (next.start <= current.end + 1) {
        current = MissingRange(start: current.start, end: next.end > current.end ? next.end : current.end);
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }
}

// 解析类型结果
class ParseTypeResult {
  final DeviceType deviceType;
  final String? deviceId;
  final ParseStage stage;
  final ErrorCode errorCode;

  const ParseTypeResult({
    required this.deviceType,
    this.deviceId,
    this.stage = ParseStage.unspecified,
    this.errorCode = ErrorCode.unspecified,
  });

  Map<String, dynamic> toJson() => {
    'deviceType': deviceType.name,
    'deviceId': deviceId,
    'stage': stage.name,
    'errorCode': errorCode.name,
  };
}

// 失败记录
class FailureRecord {
  final String stage;
  final DeviceType? deviceType;
  final String? esnSuffix;
  final String? deviceId;
  final ErrorCode errorCode;
  final Map<String, dynamic>? params;

  const FailureRecord({
    required this.stage,
    this.deviceType,
    this.esnSuffix,
    this.deviceId,
    required this.errorCode,
    this.params,
  });

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'deviceType': deviceType?.name,
    'esnSuffix': esnSuffix,
    'deviceId': deviceId,
    'errorCode': errorCode.name,
    'params': params,
  };
}

// 设备状态
class DeviceStatus {
  final String esn;
  final String esnSuffix;
  final DeviceType deviceType;
  final String deviceId;
  final String currentIp;

  CpdActiveState state = CpdActiveState.idle;
  Result result = Result.unspecified;
  ErrorCode errorCode = ErrorCode.unspecified;
  TransferStage transferStage = TransferStage.unspecified;

  int receivedChunks = 0;
  int totalChunks = 0;
  int progressPercent = 0;

  List<MissingRange> missingRanges = [];
  int receivedHighWatermark = 0;
  DateTime? lastActivityTime;
  DateTime? parseCompleteTime;

  bool get isTerminal =>
      state == CpdActiveState.completed ||
      state == CpdActiveState.partialSuccess ||
      state == CpdActiveState.failed;

  DeviceStatus({
    required this.esn,
    required this.esnSuffix,
    required this.deviceType,
    required this.deviceId,
    required this.currentIp,
  });
}

// 下发会话信息
class CpdSession {
  final Uint8List sessionId;
  final String fileName;
  final int fileSize;
  final Uint8List fileSha256;
  final String nodeId;
  final int expandedSize;
  final int requiredWorkspace;
  final int chunkSize;
  final int totalChunks;

  CpdActiveState activeState = CpdActiveState.idle;

  final List<DeviceStatus> devices = [];
  final List<FailureRecord> failures = [];

  int sentChunkCount = 0;
  int totalSentChunks = 0;

  CpdSession({
    required this.sessionId,
    required this.fileName,
    required this.fileSize,
    required this.fileSha256,
    required this.nodeId,
    required this.expandedSize,
    required this.requiredWorkspace,
    required this.chunkSize,
    required this.totalChunks,
  });
}
