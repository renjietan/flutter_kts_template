import 'cpds_enums.dart';

class CpdsUpload {
  const CpdsUpload({required this.fileName, required this.fileSize});

  final String fileName;
  final int fileSize;

  factory CpdsUpload.fromJson(Map<String, dynamic> json) => CpdsUpload(
    fileName: json['fileName'] as String? ?? '',
    fileSize: _asInt(json['fileSize']),
  );

  Map<String, dynamic> toJson() => {'fileName': fileName, 'fileSize': fileSize};
}

class CpdsUnit {
  CpdsUnit({
    required this.id,
    required this.name,
    required this.nodeIds,
    required this.subUnits,
  });

  final String id;
  final String name;
  final List<String> nodeIds;
  final List<CpdsUnit> subUnits;

  factory CpdsUnit.fromJson(Map<String, dynamic> json) => CpdsUnit(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nodeIds: _stringList(json['nodeIds']),
    subUnits: _listOfMaps(json['subUnits'])
        .map((item) => CpdsUnit.fromJson(item))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nodeIds': nodeIds,
    'subUnits': subUnits.map((item) => item.toJson()).toList(),
  };
}

class CpdsDevice {
  const CpdsDevice({
    required this.id,
    required this.type,
    required this.model,
    required this.alias,
    required this.ip,
  });

  final String id;
  final CpdsDeviceType type;
  final String model;
  final String alias;
  final String ip;

  factory CpdsDevice.fromJson(Map<String, dynamic> json) => CpdsDevice(
    id: json['id'] as String? ?? '',
    type: CpdsDeviceType.fromValue(json['type']),
    model: json['model'] as String? ?? '',
    alias: json['alias'] as String? ?? '',
    ip: json['ip'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'model': model,
    'alias': alias,
    'ip': ip,
  };

  String get key => '${type.value}:$id';
}

/// 未来战士分组下聚合出的设备，携带其所属 nodeType==1 节点的 id 与名称。
class CpdsFutureWarriorDevice {
  const CpdsFutureWarriorDevice({
    required this.device,
    required this.nodeId,
    required this.nodeName,
  });

  final CpdsDevice device;
  final String nodeId;
  final String nodeName;

  /// 使用「节点 id + 设备 key」保证跨节点也不去重。
  String get key => '$nodeId:${device.key}';
}

class CpdsNode {
  CpdsNode({
    required this.id,
    required this.guid,
    required this.name,
    required this.networkSegment,
    required this.nodeType,
    required this.model,
    required this.devices,
  });

  final String id;
  final String guid;
  final String name;
  final String networkSegment;
  final int nodeType;
  final String model;
  final List<CpdsDevice> devices;

  factory CpdsNode.fromJson(Map<String, dynamic> json) => CpdsNode(
    id: json['id'] as String? ?? '',
    guid: json['guid'] as String? ?? '',
    name: json['name'] as String? ?? '',
    networkSegment: json['networkSegment'] as String? ?? '',
    nodeType: _asInt(json['nodeType']),
    model: json['model'] as String? ?? '',
    devices: _listOfMaps(json['devices'])
        .map((item) => CpdsDevice.fromJson(item))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'guid': guid,
    'name': name,
    'networkSegment': networkSegment,
    'nodeType': nodeType,
    'model': model,
    'devices': devices.map((item) => item.toJson()).toList(),
  };
}

class CpdsPackage {
  CpdsPackage({
    required this.fileName,
    required this.fileSize,
    required this.expandedSize,
    required this.requiredWorkspace,
    required this.units,
    required this.nodes,
  });

  final String fileName;
  final int fileSize;
  final int expandedSize;
  final int requiredWorkspace;
  final List<CpdsUnit> units;
  final List<CpdsNode> nodes;

  factory CpdsPackage.fromJson(Map<String, dynamic> json) => CpdsPackage(
    fileName: json['fileName'] as String? ?? '',
    fileSize: _asInt(json['fileSize']),
    expandedSize: _asInt(json['expandedSize']),
    requiredWorkspace: _asInt(json['requiredWorkspace']),
    units: _listOfMaps(json['units'])
        .map((item) => CpdsUnit.fromJson(item))
        .toList(),
    nodes: _listOfMaps(json['nodes'])
        .map((item) => CpdsNode.fromJson(item))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileSize': fileSize,
    'expandedSize': expandedSize,
    'requiredWorkspace': requiredWorkspace,
    'units': units.map((item) => item.toJson()).toList(),
    'nodes': nodes.map((item) => item.toJson()).toList(),
  };
}

class CpdsFailure {
  const CpdsFailure({
    required this.stage,
    this.deviceType = CpdsDeviceType.unspecified,
    this.esnSuffix = '',
    this.deviceId = '',
    required this.errorCode,
    this.params = const {},
  });

  final String stage;
  final CpdsDeviceType deviceType;
  final String esnSuffix;
  final String deviceId;
  final CpdsErrorCode errorCode;
  final Map<String, dynamic> params;

  factory CpdsFailure.fromJson(Map<String, dynamic> json) => CpdsFailure(
    stage: json['stage'] as String? ?? '',
    deviceType: CpdsDeviceType.fromValue(json['deviceType']),
    esnSuffix: json['esnSuffix'] as String? ?? '',
    deviceId: json['deviceId'] as String? ?? '',
    errorCode: CpdsErrorCode.fromValue(json['errorCode']),
    params: _asMap(json['params']),
  );

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'deviceType': deviceType.value,
    'esnSuffix': esnSuffix,
    'deviceId': deviceId,
    'errorCode': errorCode.value,
    'params': params,
  };
}

class CpdsDeviceStatusView {
  const CpdsDeviceStatusView({
    required this.device,
    this.esnSuffix = '',
    this.currentIp = '',
    this.status = CpdsDeviceStatus.pending,
    this.progress = 0,
    this.receivedChunks = 0,
    this.totalChunks = 0,
    this.terminal = false,
    this.success = false,
    this.errorCode = CpdsErrorCode.unspecified,
  });

  final CpdsDevice device;
  final String esnSuffix;
  final String currentIp;
  final CpdsDeviceStatus status;
  final int progress;
  final int receivedChunks;
  final int totalChunks;
  final bool terminal;
  final bool success;
  final CpdsErrorCode errorCode;

  factory CpdsDeviceStatusView.fromJson(Map<String, dynamic> json) =>
      CpdsDeviceStatusView(
        device: CpdsDevice.fromJson(_asMap(json['device'])),
        esnSuffix: json['esnSuffix'] as String? ?? '',
        currentIp: json['currentIp'] as String? ?? '',
        status: CpdsDeviceStatus.fromApiName(json['status']),
        progress: _asInt(json['progress']),
        receivedChunks: _asInt(json['receivedChunks']),
        totalChunks: _asInt(json['totalChunks']),
        terminal: json['terminal'] as bool? ?? false,
        success: json['success'] as bool? ?? false,
        errorCode: CpdsErrorCode.fromValue(json['errorCode']),
      );

  Map<String, dynamic> toJson() => {
    'device': device.toJson(),
    'esnSuffix': esnSuffix,
    'currentIp': currentIp,
    'status': status.apiName,
    'progress': progress,
    'receivedChunks': receivedChunks,
    'totalChunks': totalChunks,
    'terminal': terminal,
    'success': success,
    'errorCode': errorCode.value,
  };
}

class CpdsSessionView {
  const CpdsSessionView({
    required this.sessionId,
    required this.activeState,
    required this.nodeId,
    required this.devices,
    required this.failures,
    required this.sentChunks,
    required this.totalChunks,
    required this.sendingProgress,
    required this.retransmitting,
    required this.pendingChunks,
    this.lastStageIndex = -1,
  });

  final String sessionId;
  final CpdsActiveState activeState;
  final String nodeId;
  final List<CpdsDeviceStatusView> devices;
  final List<CpdsFailure> failures;
  final int sentChunks;
  final int totalChunks;
  final int sendingProgress;
  final bool retransmitting;
  final int pendingChunks;
  final int lastStageIndex;

  factory CpdsSessionView.fromJson(Map<String, dynamic> json) =>
      CpdsSessionView(
        sessionId: json['sessionId'] as String? ?? '',
        activeState: CpdsActiveState.fromApiName(json['activeState']),
        nodeId: json['nodeId'] as String? ?? '',
        devices: _listOfMaps(json['devices'])
            .map((item) => CpdsDeviceStatusView.fromJson(item))
            .toList(),
        failures: _listOfMaps(json['failures'])
            .map((item) => CpdsFailure.fromJson(item))
            .toList(),
        sentChunks: _asInt(json['sentChunks']),
        totalChunks: _asInt(json['totalChunks']),
        sendingProgress: _asInt(json['sendingProgress']),
        retransmitting: json['retransmitting'] as bool? ?? false,
        pendingChunks: _asInt(json['pendingChunks']),
        lastStageIndex: _asInt(json['lastStageIndex'], defaultValue: -1),
      );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'activeState': activeState.apiName,
    'nodeId': nodeId,
    'devices': devices.map((item) => item.toJson()).toList(),
    'failures': failures.map((item) => item.toJson()).toList(),
    'sentChunks': sentChunks,
    'totalChunks': totalChunks,
    'sendingProgress': sendingProgress,
    'retransmitting': retransmitting,
    'pendingChunks': pendingChunks,
    'lastStageIndex': lastStageIndex,
  };
}

class CpdsApplicationState {
  CpdsApplicationState({
    this.upload,
    this.package,
    this.selectedNodeId = '',
    this.selectedFutureWarriorUnitId = '',
    this.canDistribute = false,
    this.active = false,
    this.session,
  });

  CpdsUpload? upload;
  CpdsPackage? package;
  String selectedNodeId;
  String selectedFutureWarriorUnitId;
  bool canDistribute;
  bool active;
  CpdsSessionView? session;

  factory CpdsApplicationState.fromJson(Map<String, dynamic> json) =>
      CpdsApplicationState(
        upload: _nullableMap(json['upload'], CpdsUpload.fromJson),
        package: _nullableMap(json['package'], CpdsPackage.fromJson),
        selectedNodeId: json['selectedNodeId'] as String? ?? '',
        selectedFutureWarriorUnitId:
            json['selectedFutureWarriorUnitId'] as String? ?? '',
        canDistribute: json['canDistribute'] as bool? ?? false,
        active: json['active'] as bool? ?? false,
        session: _nullableMap(json['session'], CpdsSessionView.fromJson),
      );

  Map<String, dynamic> toJson() => {
    'upload': upload?.toJson(),
    'package': package?.toJson(),
    'selectedNodeId': selectedNodeId,
    'selectedFutureWarriorUnitId': selectedFutureWarriorUnitId,
    'canDistribute': canDistribute,
    'active': active,
    'session': session?.toJson(),
  };
}

class CpdsNetworkInterface {
  const CpdsNetworkInterface({
    required this.name,
    required this.index,
    required this.ipv4,
  });

  final String name;
  final int index;
  final String ipv4;

  factory CpdsNetworkInterface.fromJson(Map<String, dynamic> json) =>
      CpdsNetworkInterface(
        name: json['name'] as String? ?? '',
        index: _asInt(json['index']),
        ipv4: json['ipv4'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'index': index,
    'ipv4': ipv4,
  };
}

int _asInt(Object? value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? defaultValue;
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

T? _nullableMap<T>(
  Object? value,
  T Function(Map<String, dynamic>) parser,
) {
  if (value == null) return null;
  return parser(_asMap(value));
}
