import 'dart:io';
import 'dart:typed_data';

import '../model/cpds_enums.dart';
import '../model/cpds_models.dart';
import '../protocol/cpd_protocol.dart';

class _CpdsDiscoveredClient {
  _CpdsDiscoveredClient({
    required this.esn,
    required this.instanceNonce,
    required this.deviceTypes,
    required this.currentIp,
    required this.subnetMask,
  });

  final String esn;
  Uint8List instanceNonce;
  List<CpdsDeviceType> deviceTypes;
  String currentIp;
  String subnetMask;
}

class _CpdsAssignment {
  _CpdsAssignment({
    required this.deviceType,
    required this.esn,
    required this.nodeId,
    required this.deviceId,
  });

  final CpdsDeviceType deviceType;
  final String esn;
  final String nodeId;
  final String deviceId;

  Map<int, dynamic> toBody() => {
    1: deviceType.value,
    2: esn,
    3: nodeId,
    4: deviceId,
  };
}

class _CpdsClientState {
  _CpdsClientState(this.discovery);

  final _CpdsDiscoveredClient discovery;
  final List<_CpdsAssignment> assignments = [];
  final List<int> statusIndexes = [];
  bool authenticated = false;
  bool transferDone = false;
  bool terminal = false;
  bool success = false;
  CpdsErrorCode errorCode = CpdsErrorCode.unspecified;
  DateTime? waitStarted;
  DateTime? lastReply;
  DateTime? highWaterAt;
  int highWater = 0;
  DateTime? parseDeadline;
  DateTime? silencePaused;
}

class CpdsSessionMachine {
  CpdsSessionMachine({
    required this.nodeId,
    required List<CpdsDevice> expected,
  }) : _expected = List<CpdsDevice>.from(expected);

  final String nodeId;
  final List<CpdsDevice> _expected;

  Uint8List _sessionId = Uint8List(0);
  CpdsActiveState _state = CpdsActiveState.idle;
  final Map<String, _CpdsDiscoveredClient> _discoveries = {};
  final Map<String, _CpdsClientState> _clients = {};
  final List<_CpdsAssignment> _assignments = [];
  final List<CpdsDeviceStatusView> _statuses = [];
  final List<CpdsFailure> _failures = [];
  bool _discoveryMalformed = false;
  int _sentChunks = 0;
  int _totalChunks = 0;
  bool _retransmitting = false;
  int _pendingChunks = 0;

  CpdsActiveState get state => _state;
  Uint8List get sessionId => Uint8List.fromList(_sessionId);

  void begin(Uint8List sessionId) {
    if (sessionId.length != 16 || _state != CpdsActiveState.idle) {
      throw StateError('invalid session start');
    }
    _sessionId = Uint8List.fromList(sessionId);
    _state = CpdsActiveState.discovering;
  }

  void recordDiscovery(
    String esn,
    Uint8List nonce,
    List<CpdsDeviceType> deviceTypes,
    String currentIp,
    String subnetMask,
  ) {
    if (_state != CpdsActiveState.discovering) return;
    if (!_validDiscovery(esn, nonce, deviceTypes, currentIp, subnetMask)) {
      _discoveryMalformed = true;
      return;
    }
    final key = '$esn:${hexEncode(nonce)}';
    final previous = _discoveries[key];
    if (previous != null) {
      previous.currentIp = currentIp;
      previous.subnetMask = subnetMask;
      return;
    }
    _discoveries[key] = _CpdsDiscoveredClient(
      esn: esn,
      instanceNonce: Uint8List.fromList(nonce),
      deviceTypes: List<CpdsDeviceType>.from(deviceTypes),
      currentIp: currentIp,
      subnetMask: subnetMask,
    );
  }

  void finishDiscovery() {
    if (_state != CpdsActiveState.discovering) {
      throw StateError('not in discovery');
    }
    if (_discoveryMalformed) {
      _failGlobal(
        CpdsErrorCode.invalidMessage,
        const {'field': 'discoverRsp'},
      );
      return;
    }

    final byEsn = <String, List<_CpdsDiscoveredClient>>{};
    for (final discovery in _discoveries.values) {
      byEsn.putIfAbsent(discovery.esn, () => []).add(discovery);
    }
    for (final entry in byEsn.entries) {
      if (entry.value.length > 1) {
        final instances = entry.value
            .map((item) => hexEncode(item.instanceNonce))
            .map((value) => value.substring(value.length - 8))
            .toList()
          ..sort();
        _failGlobal(
          CpdsErrorCode.esnConflict,
          {'esnSuffix': suffix(entry.key), 'instances': instances.join(', ')},
        );
        return;
      }
    }

    final clientsByType = <CpdsDeviceType, List<_CpdsDiscoveredClient>>{};
    for (final discovery in _discoveries.values) {
      for (final type in discovery.deviceTypes) {
        clientsByType.putIfAbsent(type, () => []).add(discovery);
      }
    }
    final expectedByType = <CpdsDeviceType, List<CpdsDevice>>{};
    for (final device in _expected) {
      expectedByType.putIfAbsent(device.type, () => []).add(device);
    }
    final types = <CpdsDeviceType>{
      ...expectedByType.keys,
      ...clientsByType.keys,
    }.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final type in types) {
      final expectedCount = expectedByType[type]?.length ?? 0;
      final actualCount = clientsByType[type]?.length ?? 0;
      if (expectedCount != actualCount) {
        _failures.add(
          CpdsFailure(
            stage: 'DISCOVERY',
            deviceType: type,
            errorCode: CpdsErrorCode.discoveryMismatch,
            params: {'expected': expectedCount, 'actual': actualCount},
          ),
        );
      }
      clientsByType[type]?.sort((a, b) => a.esn.compareTo(b.esn));
    }

    final nextByType = <CpdsDeviceType, int>{};
    for (final device in _expected) {
      final list = clientsByType[device.type] ?? const [];
      final index = nextByType[device.type] ?? 0;
      if (index >= list.length) {
        _statuses.add(
          CpdsDeviceStatusView(device: device, status: CpdsDeviceStatus.pending),
        );
        continue;
      }
      final discovery = list[index];
      nextByType[device.type] = index + 1;
      final assignment = _CpdsAssignment(
        deviceType: device.type,
        esn: discovery.esn,
        nodeId: nodeId,
        deviceId: device.id,
      );
      _assignments.add(assignment);
      final client = _clients.putIfAbsent(
        discovery.esn,
        () => _CpdsClientState(discovery),
      );
      client.assignments.add(assignment);
      client.statusIndexes.add(_statuses.length);
      _statuses.add(
        CpdsDeviceStatusView(
          device: device,
          esnSuffix: suffix(discovery.esn),
          currentIp: discovery.currentIp,
          status: CpdsDeviceStatus.discovered,
        ),
      );
    }

    for (final type in types) {
      final list = clientsByType[type] ?? const [];
      final start = nextByType[type] ?? 0;
      for (final discovery in list.skip(start)) {
        _statuses.add(
          CpdsDeviceStatusView(
            device: CpdsDevice(id: '', type: type, model: '', alias: '', ip: ''),
            esnSuffix: suffix(discovery.esn),
            currentIp: discovery.currentIp,
            status: CpdsDeviceStatus.ignored,
            terminal: true,
          ),
        );
      }
    }

    if (_assignments.isEmpty) {
      if (_failures.isNotEmpty) {
        _state = CpdsActiveState.failed;
      } else {
        _state = CpdsActiveState.completed;
      }
    } else if (_failures.any(
      (failure) =>
          failure.stage == 'DISCOVERY' &&
          failure.errorCode == CpdsErrorCode.discoveryMismatch,
    )) {
      _state = CpdsActiveState.awaitingDiscoveryConfirmation;
    } else {
      _state = CpdsActiveState.authenticating;
    }
    return;
  }

  void resolveDiscoveryMismatch(bool proceed) {
    if (_state != CpdsActiveState.awaitingDiscoveryConfirmation) return;
    if (proceed) {
      _state = CpdsActiveState.authenticating;
    } else {
      for (final client in _clients.values) {
        _failClient(
          client,
          'DISCOVERY',
          CpdsErrorCode.skippedAfterPreviousFailure,
        );
      }
      _state = CpdsActiveState.failed;
    }
  }

  void recordAuth(Map<int, dynamic> body) {
    if (_state != CpdsActiveState.authenticating) return;
    final client = _clientForIdentity(_message(body, 1));
    if (client == null) return;
    final result = CpdResult.fromValue(body[2]);
    if (result == CpdResult.unspecified) return;
    if (result != CpdResult.success) {
      final code = CpdsErrorCode.fromValue(body[5]);
      _failClient(client, 'AUTHENTICATION', code);
      _failRemaining(client, 'AUTHENTICATION');
      _state = CpdsActiveState.failed;
      return;
    }
    final node = _string(body, 3);
    final bindings = _messageList(body, 4);
    if (node != nodeId || !_bindingsMatch(client.assignments, bindings)) {
      _failClient(
        client,
        'AUTHENTICATION',
        CpdsErrorCode.authBindingMissing,
      );
      _failRemaining(client, 'AUTHENTICATION');
      _state = CpdsActiveState.failed;
      return;
    }
    client.authenticated = true;
    _setClientStatus(client, CpdsDeviceStatus.authenticated);
    if (_clients.values.every((item) => item.authenticated)) {
      _state = CpdsActiveState.transferring;
    }
  }

  void finishAuthentication() {
    if (_state != CpdsActiveState.authenticating) return;
    for (final client in _clients.values) {
      if (!client.authenticated) {
        _failClient(client, 'AUTHENTICATION', CpdsErrorCode.authTimeout);
      }
    }
    for (final client in _clients.values) {
      if (!client.terminal) {
        _failClient(
          client,
          'AUTHENTICATION',
          CpdsErrorCode.skippedAfterPreviousFailure,
        );
      }
    }
    _state = CpdsActiveState.failed;
  }

  void beginTransferWait(DateTime now) {
    for (final client in _clients.values) {
      if (client.terminal || client.transferDone) continue;
      client.waitStarted ??= now;
      client.lastReply ??= now;
      client.highWaterAt ??= now;
    }
  }

  void recordTransferProgress(Map<int, dynamic> body) {
    final client = _clientForIdentity(_message(body, 1));
    if (client == null || client.terminal || client.transferDone) return;
    final total = _int(body, 3);
    final received = _int(body, 2);
    final percent = _int(body, 4);
    if (total == 0 || received > total || percent > 100) return;
    client.lastReply = DateTime.now();
    if (received > client.highWater) {
      client.highWater = received;
      client.highWaterAt = DateTime.now();
    }
    _setClientStatus(
      client,
      CpdsDeviceStatus.receiving,
      progress: percent,
      receivedChunks: received,
      totalChunks: total,
    );
  }

  void recordTransferComplete(Map<int, dynamic> body) {
    final client = _clientForIdentity(_message(body, 1));
    if (client == null || client.terminal || client.transferDone) return;
    final result = CpdResult.fromValue(body[2]);
    final stage = CpdTransferStage.fromValue(body[3]);
    if (result == CpdResult.unspecified || stage == CpdTransferStage.unspecified) {
      return;
    }
    if (result != CpdResult.success) {
      _failClient(
        client,
        'TRANSFER',
        CpdsErrorCode.fromValue(body[5]),
      );
      _recalculateState();
      return;
    }
    if (stage != CpdTransferStage.cacheReuse &&
        stage != CpdTransferStage.verify) {
      return;
    }
    client.transferDone = true;
    client.parseDeadline = DateTime.now().add(
      const Duration(seconds: 35),
    );
    _setClientStatus(
      client,
      CpdsDeviceStatus.waitingParse,
      progress: 100,
      receivedChunks: _int(body, 4),
    );
    _recalculateState();
  }

  bool recordLossPack(Map<int, dynamic> body) {
    final client = _clientForIdentity(_message(body, 1));
    if (client == null || client.terminal || client.transferDone) return false;
    if (_totalChunks == 0) return false;
    final ranges = _messageList(body, 2);
    if (ranges.isEmpty) return false;
    var missingCount = 0;
    for (final range in ranges) {
      final start = _int(range, 1);
      final end = _int(range, 2);
      if (start > end || end >= _totalChunks) return false;
      missingCount += end - start + 1;
    }
    final received = _totalChunks - missingCount;
    client.lastReply = DateTime.now();
    if (received > client.highWater) {
      client.highWater = received;
      client.highWaterAt = DateTime.now();
    }
    final percent = ((received * 100) ~/ _totalChunks).clamp(0, 100);
    _setClientStatus(
      client,
      CpdsDeviceStatus.receiving,
      progress: percent,
      receivedChunks: received,
      totalChunks: _totalChunks,
    );
    return true;
  }

  void recordParseComplete(Map<int, dynamic> body) {
    final client = _clientForIdentity(_message(body, 1));
    if (client == null || client.terminal) return;
    final result = CpdResult.fromValue(body[2]);
    final requestNode = _string(body, 3);
    final bindings = _messageList(body, 4);
    final typeResults = _messageList(body, 5);
    if (result == CpdResult.unspecified ||
        requestNode != nodeId ||
        !_bindingsMatch(client.assignments, bindings) ||
        typeResults.length != client.assignments.length) {
      return;
    }
    client.transferDone = true;
    if (result == CpdResult.success) {
      client.terminal = true;
      client.success = true;
      _setClientStatus(
        client,
        CpdsDeviceStatus.completed,
        progress: 100,
        terminal: true,
        success: true,
      );
    } else {
      client.terminal = true;
      client.success = false;
      client.errorCode = CpdsErrorCode.fromValue(body[6]);
      for (var index = 0; index < client.assignments.length; index++) {
        final resultBody = typeResults[index];
        final statusIndex = client.statusIndexes[index];
        final typeResult = CpdResult.fromValue(resultBody[3]);
        if (typeResult == CpdResult.success) {
          _setStatusAt(
            statusIndex,
            CpdsDeviceStatus.completed,
            progress: 100,
            terminal: true,
            success: true,
          );
        } else {
          final code = CpdsErrorCode.fromValue(resultBody[5]);
          _setStatusAt(
            statusIndex,
            CpdsDeviceStatus.failed,
            progress: 100,
            terminal: true,
            success: false,
            errorCode: code,
          );
          final assignment = client.assignments[index];
          _failures.add(
            CpdsFailure(
              stage: 'PARSE',
              deviceType: assignment.deviceType,
              esnSuffix: suffix(client.discovery.esn),
              deviceId: assignment.deviceId,
              errorCode: code,
              params: {
                'parseStage': CpdParseStage.fromValue(resultBody[4]).value,
              },
            ),
          );
        }
      }
    }
    _recalculateState();
  }

  void checkDeadlines(DateTime now) {
    for (final client in _clients.values) {
      if (client.terminal) continue;
      if (client.transferDone) {
        final deadline = client.parseDeadline;
        if (deadline != null && now.isAfter(deadline)) {
          _failClient(client, 'PARSE', CpdsErrorCode.parseTimeout);
        }
        continue;
      }
      final lastReply = client.lastReply;
      if (lastReply != null &&
          now.difference(lastReply) > const Duration(seconds: 10)) {
        _failClient(
          client,
          'TRANSFER',
          CpdsErrorCode.transferSilenceTimeout,
        );
        continue;
      }
      final highWaterAt = client.highWaterAt;
      if (highWaterAt != null &&
          now.difference(highWaterAt) > const Duration(seconds: 30)) {
        _failClient(
          client,
          'TRANSFER',
          CpdsErrorCode.transferNoProgress,
        );
      }
    }
    _recalculateState();
  }

  bool hasTransferPending() =>
      _clients.values.any((client) => !client.terminal && !client.transferDone);

  void failActive(String stage, CpdsErrorCode code) {
    for (final client in _clients.values) {
      if (!client.terminal) _failClient(client, stage, code);
    }
    if (_clients.isEmpty) {
      _failures.add(
        CpdsFailure(stage: stage, errorCode: code),
      );
      _state = CpdsActiveState.failed;
      return;
    }
    _recalculateState();
  }

  void setSendProgress(int sent, int total, int pending, bool retransmitting) {
    _sentChunks = sent;
    _totalChunks = total;
    _pendingChunks = pending;
    _retransmitting = retransmitting;
  }

  List<Map<int, dynamic>> get assignmentBodies =>
      _assignments.map((item) => item.toBody()).toList();

  CpdsSessionView view() {
    final progress = _totalChunks == 0
        ? 0
        : ((_sentChunks * 100) ~/ _totalChunks).clamp(0, 100);
    return CpdsSessionView(
      sessionId: hexEncode(_sessionId),
      activeState: _state,
      nodeId: nodeId,
      devices: _statusView(),
      failures: List<CpdsFailure>.from(_failures),
      sentChunks: _sentChunks,
      totalChunks: _totalChunks,
      sendingProgress: progress,
      retransmitting: _retransmitting,
      pendingChunks: _pendingChunks,
    );
  }

  List<CpdsDeviceStatusView> _statusView() {
    if (_statuses.isNotEmpty) {
      return _statuses
          .map(
            (item) => CpdsDeviceStatusView(
              device: item.device,
              esnSuffix: item.esnSuffix,
              currentIp: item.currentIp,
              status: item.status,
              progress: item.progress,
              receivedChunks: item.receivedChunks,
              totalChunks: item.totalChunks,
              terminal: item.terminal,
              success: item.success,
              errorCode: item.errorCode,
            ),
          )
          .toList();
    }
    if (_state != CpdsActiveState.discovering &&
        _state != CpdsActiveState.failed) {
      return const [];
    }
    final byType = <CpdsDeviceType, List<_CpdsDiscoveredClient>>{};
    for (final discovery in _discoveries.values) {
      for (final type in discovery.deviceTypes) {
        byType.putIfAbsent(type, () => []).add(discovery);
      }
    }
    final next = <CpdsDeviceType, int>{};
    final statuses = <CpdsDeviceStatusView>[];
    for (final device in _expected) {
      final list = byType[device.type] ?? const [];
      final index = next[device.type] ?? 0;
      if (index >= list.length) continue;
      final discovery = list[index];
      next[device.type] = index + 1;
      statuses.add(
        CpdsDeviceStatusView(
          device: device,
          esnSuffix: suffix(discovery.esn),
          currentIp: discovery.currentIp,
          status: CpdsDeviceStatus.discovered,
        ),
      );
    }
    return statuses;
  }

  void _recalculateState() {
    var allTerminal = _clients.isNotEmpty;
    var allTransferDone = _clients.isNotEmpty;
    var hasExecutionFailure = false;
    var hasDiscoveryMismatch = false;
    for (final failure in _failures) {
      if (failure.stage == 'DISCOVERY' &&
          failure.errorCode == CpdsErrorCode.discoveryMismatch) {
        hasDiscoveryMismatch = true;
      } else {
        hasExecutionFailure = true;
      }
    }
    for (final client in _clients.values) {
      allTerminal = allTerminal && client.terminal;
      allTransferDone = allTransferDone && (client.transferDone || client.terminal);
    }
    if (allTerminal) {
      final successCount = _clients.values.where((item) => item.success).length;
      if (successCount == 0) {
        _state = CpdsActiveState.failed;
      } else if (hasDiscoveryMismatch ||
          hasExecutionFailure ||
          successCount < _clients.length) {
        _state = CpdsActiveState.partialSuccess;
      } else {
        _state = CpdsActiveState.completed;
      }
      return;
    }
    if (hasExecutionFailure) {
      _state = CpdsActiveState.drainingAfterFailure;
    } else if (allTransferDone) {
      _state = CpdsActiveState.waitingParse;
    } else {
      _state = CpdsActiveState.transferring;
    }
  }

  _CpdsClientState? _clientForIdentity(Map<int, dynamic> identity) {
    final esn = _string(identity, 1);
    final client = _clients[esn];
    if (client == null) return null;
    final types = _enumList(identity, 2);
    if (!_sameTypeOrder(client.discovery.deviceTypes, types)) return null;
    return client;
  }

  void _setClientStatus(
    _CpdsClientState client,
    CpdsDeviceStatus status, {
    int progress = 0,
    int receivedChunks = 0,
    int totalChunks = 0,
    bool terminal = false,
    bool success = false,
    CpdsErrorCode errorCode = CpdsErrorCode.unspecified,
  }) {
    for (final index in client.statusIndexes) {
      _setStatusAt(
        index,
        status,
        progress: progress,
        receivedChunks: receivedChunks,
        totalChunks: totalChunks,
        terminal: terminal,
        success: success,
        errorCode: errorCode,
      );
    }
  }

  void _setStatusAt(
    int index,
    CpdsDeviceStatus status, {
    int progress = 0,
    int receivedChunks = 0,
    int totalChunks = 0,
    bool terminal = false,
    bool success = false,
    CpdsErrorCode errorCode = CpdsErrorCode.unspecified,
  }) {
    if (index < 0 || index >= _statuses.length) return;
    final old = _statuses[index];
    _statuses[index] = CpdsDeviceStatusView(
      device: old.device,
      esnSuffix: old.esnSuffix,
      currentIp: old.currentIp,
      status: status,
      progress: progress,
      receivedChunks: receivedChunks,
      totalChunks: totalChunks,
      terminal: terminal,
      success: success,
      errorCode: errorCode,
    );
  }

  void _failClient(
    _CpdsClientState client,
    String stage,
    CpdsErrorCode code,
  ) {
    if (client.terminal) return;
    client.terminal = true;
    client.success = false;
    client.errorCode = code;
    _setClientStatus(
      client,
      CpdsDeviceStatus.failed,
      terminal: true,
      success: false,
      errorCode: code,
    );
    if (client.assignments.isEmpty) {
      _failures.add(
        CpdsFailure(
          stage: stage,
          esnSuffix: suffix(client.discovery.esn),
          errorCode: code,
        ),
      );
      return;
    }
    for (final assignment in client.assignments) {
      _failures.add(
        CpdsFailure(
          stage: stage,
          deviceType: assignment.deviceType,
          esnSuffix: suffix(client.discovery.esn),
          deviceId: assignment.deviceId,
          errorCode: code,
        ),
      );
    }
  }

  void _failRemaining(_CpdsClientState except, String stage) {
    for (final client in _clients.values) {
      if (client != except && !client.terminal) {
        _failClient(
          client,
          stage,
          CpdsErrorCode.skippedAfterPreviousFailure,
        );
      }
    }
  }

  void _failGlobal(CpdsErrorCode code, Map<String, dynamic> params) {
    _state = CpdsActiveState.failed;
    _failures.add(
      CpdsFailure(
        stage: 'DISCOVERY',
        errorCode: code,
        params: params,
      ),
    );
  }
}

bool _validDiscovery(
  String esn,
  Uint8List nonce,
  List<CpdsDeviceType> deviceTypes,
  String currentIp,
  String subnetMask,
) {
  if (esn.length != 39 || !RegExp(r'^\d{39}$').hasMatch(esn)) return false;
  if (nonce.length != 16 || deviceTypes.isEmpty) return false;
  final seen = <CpdsDeviceType>{};
  var hasCcuAudio = false;
  for (final type in deviceTypes) {
    if (type == CpdsDeviceType.unspecified || seen.contains(type)) return false;
    seen.add(type);
    hasCcuAudio = hasCcuAudio || type == CpdsDeviceType.ccuAudio;
  }
  if (hasCcuAudio && deviceTypes.length != 1) return false;
  if (_ipv4(currentIp) == null) return false;
  if (_ipv4(subnetMask) == null) return false;
  return true;
}

bool _bindingsMatch(
  List<_CpdsAssignment> assignments,
  List<Map<int, dynamic>> bindings,
) {
  if (assignments.length != bindings.length) return false;
  final wanted = assignments
      .map((item) => '${item.deviceType.value}:${item.deviceId}')
      .toSet();
  for (final binding in bindings) {
    final type = CpdsDeviceType.fromValue(binding[1]);
    final deviceId = _string(binding, 2);
    if (!wanted.contains('${type.value}:$deviceId')) return false;
  }
  return true;
}

List<CpdsDeviceType> _enumList(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is CpdPackedEnums) {
    return value.values
        .map((item) => CpdsDeviceType.fromValue(item))
        .toList();
  }
  if (value is Uint8List) {
    return _parsePackedVarints(value)
        .map((item) => CpdsDeviceType.fromValue(item))
        .toList();
  }
  if (value is List) {
    return value
        .map((item) => CpdsDeviceType.fromValue(item))
        .toList();
  }
  if (value != null) return [CpdsDeviceType.fromValue(value)];
  return const [];
}

List<int> _parsePackedVarints(Uint8List data) {
  final result = <int>[];
  var offset = 0;
  while (offset < data.length) {
    var value = 0;
    var shift = 0;
    while (offset < data.length) {
      final byte = data[offset++];
      value |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    result.add(value);
  }
  return result;
}

List<Map<int, dynamic>> _messageList(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is Uint8List) {
    final single = _asMessage(value);
    return single == null ? const [] : [single];
  }
  if (value is List) {
    return value
        .map((item) => _asMessage(item))
        .whereType<Map<int, dynamic>>()
        .toList();
  }
  final single = _asMessage(value);
  return single == null ? const [] : [single];
}

Map<int, dynamic> _message(Map<int, dynamic> map, int field) {
  return _asMessage(map[field]) ?? const {};
}

Map<int, dynamic>? _asMessage(Object? value) {
  if (value is Uint8List) return CpdProtocol.parseFields(value);
  if (value is Map<int, dynamic>) return value;
  if (value is Map) return Map<int, dynamic>.from(value);
  return null;
}

String _string(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is Uint8List) return String.fromCharCodes(value);
  return value?.toString() ?? '';
}

int _int(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _sameTypeOrder(
  List<CpdsDeviceType> left,
  List<CpdsDeviceType> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String suffix(String esn) => esn.length <= 6 ? esn : esn.substring(esn.length - 6);

String hexEncode(Uint8List data) => data
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();

InternetAddress? _ipv4(String value) {
  try {
    final address = InternetAddress(value);
    return address.type == InternetAddressType.IPv4 ? address : null;
  } catch (_) {
    return null;
  }
}
