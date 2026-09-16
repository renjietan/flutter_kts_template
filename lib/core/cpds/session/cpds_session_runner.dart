import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../model/cpds_enums.dart';
import '../model/cpds_models.dart';
import '../protocol/cpd_protocol.dart';
import '../protocol/cpds_udp_transport.dart';
import 'cpds_session_machine.dart';

class CpdsPackageInput {
  const CpdsPackageInput({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.sha256,
    required this.expandedSize,
    required this.requiredWorkspace,
  });

  final String fileName;
  final String filePath;
  final int fileSize;
  final Uint8List sha256;
  final int expandedSize;
  final int requiredWorkspace;
}

class CpdsSessionRunner {
  CpdsSessionRunner({
    required this.transport,
    required this.machine,
    required this.input,
    required this.discoveryDecision,
    this.onUpdate,
  });

  final CpdsUdpTransport transport;
  final CpdsSessionMachine machine;
  final CpdsPackageInput input;
  final Stream<bool> discoveryDecision;
  final void Function(CpdsSessionView view)? onUpdate;

  StreamSubscription<CpdPacket>? _packetSubscription;
  StreamSubscription<bool>? _decisionSubscription;
  Completer<bool>? _decisionCompleter;
  bool _cancelled = false;
  final Set<int> _pendingChunks = {};
  final Set<String> _requesters = {};

  Future<void> run() async {
    _packetSubscription = transport.packets.listen(_handlePacket);
    try {
      await _discover();
      if (_cancelled || _terminal) return;

      if (machine.state == CpdsActiveState.awaitingDiscoveryConfirmation) {
        final proceed = await _waitDecision();
        machine.resolveDiscoveryMismatch(proceed);
        _updated();
        if (_terminal) return;
        if (proceed) {
          await _refreshDiscovery();
        }
      }

      await _authenticate();
      if (_cancelled || _terminal) return;

      await _transfer();
    } finally {
      await _cleanup();
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    _decisionCompleter?.complete(false);
    await _cleanup();
  }

  Future<void> _discover() async {
    final message = _packet(10, const {});
    await transport.send(message);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!_cancelled && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (_cancelled) return;
      await transport.send(message);
    }
    machine.finishDiscovery();
    _updated();
  }

  Future<void> _refreshDiscovery() async {
    final message = _packet(10, const {});
    await transport.send(message);
    await transport.send(message);
  }

  Future<void> _authenticate() async {
    final packets = _buildAuthPackets(machine.assignmentBodies);
    if (packets.isEmpty) {
      machine.failActive('AUTHENTICATION', CpdsErrorCode.authBindingMissing);
      _updated();
      return;
    }
    await _sendAll(packets);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!_cancelled && !_terminal) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (_cancelled || _terminal) return;
      if (machine.state != CpdsActiveState.authenticating) {
        break;
      }
      await _sendAll(packets);
      if (DateTime.now().isAfter(deadline)) break;
    }
    if (!_terminal) machine.finishAuthentication();
    _updated();
  }

  List<CpdPacket> _buildAuthPackets(List<Map<int, dynamic>> assignments) {
    final packets = <CpdPacket>[];
    var current = <Map<int, dynamic>>[];
    var messageId = _uuid();

    for (final assignment in assignments) {
      final candidate = [...current, assignment];
      if (_authPacketFits(messageId, candidate)) {
        current = candidate;
        continue;
      }
      if (current.isNotEmpty) {
        packets.add(_authPacket(messageId, current));
      }
      messageId = _uuid();
      current = [assignment];
    }
    if (current.isNotEmpty) {
      packets.add(_authPacket(messageId, current));
    }
    return packets;
  }

  CpdPacket _authPacket(
    Uint8List messageId,
    List<Map<int, dynamic>> assignments,
  ) {
    return CpdPacket(
      sessionId: machine.sessionId,
      messageId: messageId,
      bodyField: 12,
      body: {1: assignments},
    );
  }

  bool _authPacketFits(
    Uint8List messageId,
    List<Map<int, dynamic>> assignments,
  ) {
    try {
      CpdProtocol.encodePacket(_authPacket(messageId, assignments));
      return true;
    } on StateError {
      return false;
    }
  }

  Future<void> _transfer() async {
    final file = File(input.filePath);
    final bytes = file.readAsBytesSync();
    if (bytes.length != input.fileSize) {
      machine.failActive('TRANSFER', CpdsErrorCode.fileSizeMismatch);
      _updated();
      return;
    }
    final digest = sha256.convert(bytes).bytes;
    if (!_bytesEqual(digest, input.sha256)) {
      machine.failActive('TRANSFER', CpdsErrorCode.fileHashMismatch);
      _updated();
      return;
    }

    final chunks = _chunkBytes(bytes, CpdProtocol.chunkSize);
    machine.setSendProgress(0, chunks.length, 0, false);
    final start = _packet(20, {
      1: input.fileName,
      2: input.fileSize,
      3: Uint8List.fromList(input.sha256),
      4: input.expandedSize,
      5: input.requiredWorkspace,
      6: CpdProtocol.chunkSize,
      7: chunks.length,
    });
    final end = _packet(23, const {});
    await transport.send(start);
    await transport.send(start);

    var nextStartRefresh = DateTime.now().add(const Duration(seconds: 1));
    for (var index = 0; index < chunks.length; index++) {
      if (_cancelled || _terminal) return;
      final now = DateTime.now();
      if (!now.isBefore(nextStartRefresh)) {
        await transport.send(start);
        nextStartRefresh = now.add(const Duration(seconds: 1));
      }
      final chunkPacket = _packet(21, {
        1: index,
        2: chunks[index],
        3: CpdFixed32(_crc32(chunks[index])),
      });
      await transport.send(chunkPacket);
      machine.setSendProgress(index + 1, chunks.length, 0, false);
      _updated();
      await Future<void>.delayed(
        Duration(
          microseconds: max(1, (chunks[index].length * 8 * 1000000) ~/ 1000000),
        ),
      );
    }

    await transport.send(start);
    await transport.send(start);
    await transport.send(end);
    machine.beginTransferWait(DateTime.now());
    _updated();
    await _waitTransfer(start, end, chunks);
  }

  Future<void> _waitTransfer(
    CpdPacket start,
    CpdPacket end,
    List<Uint8List> chunks,
  ) async {
    final now = DateTime.now();
    var nextDeadlineCheck = now.add(const Duration(milliseconds: 100));
    var nextResultPing = now;
    while (!_cancelled && !_terminal) {
      if (_pendingChunks.isNotEmpty) {
        await _retransmit(start, end, chunks);
        continue;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_cancelled) return;
      final current = DateTime.now();
      if (current.isAfter(nextDeadlineCheck)) {
        machine.checkDeadlines(current);
        _updated();
        nextDeadlineCheck = current.add(const Duration(milliseconds: 100));
      }
      if (current.isAfter(nextResultPing)) {
        if (machine.hasTransferPending()) {
          await transport.send(start);
          await transport.send(end);
        }
        nextResultPing = current.add(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _retransmit(
    CpdPacket start,
    CpdPacket end,
    List<Uint8List> chunks,
  ) async {
    final indexes = _pendingChunks.toList()..sort();
    final requesters = _requesters.toList();
    _pendingChunks.clear();
    _requesters.clear();
    for (final esn in requesters) {
      machine.setRetransmitting(esn, true, DateTime.now());
    }
    try {
      machine.setSendProgress(
        chunks.length,
        chunks.length,
        indexes.length,
        true,
      );
      _updated();
      for (final index in indexes) {
        if (_cancelled || _terminal) return;
        if (index < 0 || index >= chunks.length) continue;
        final packet = _packet(21, {
          1: index,
          2: chunks[index],
          3: CpdFixed32(_crc32(chunks[index])),
        });
        await transport.send(packet);
        await Future<void>.delayed(
          Duration(
            microseconds: max(
              1,
              (chunks[index].length * 8 * 1000000) ~/ 1000000,
            ),
          ),
        );
      }
      await transport.send(start);
      await transport.send(end);
    } finally {
      final now = DateTime.now();
      for (final esn in requesters) {
        machine.setRetransmitting(esn, false, now);
      }
      machine.setSendProgress(chunks.length, chunks.length, 0, false);
      _updated();
    }
  }

  void _handlePacket(CpdPacket packet) {
    if (_cancelled || !_sameSession(packet)) return;
    switch (packet.bodyField) {
      case 11:
        _handleDiscoverRsp(packet.body);
        break;
      case 13:
        machine.recordAuth(packet.body);
        _updated();
        break;
      case 22:
        machine.recordTransferProgress(packet.body);
        _updated();
        break;
      case 25:
        machine.recordTransferComplete(packet.body);
        _updated();
        break;
      case 24:
        if (machine.recordLossPack(packet.body)) {
          _addMissingRanges(packet.body);
        }
        _updated();
        break;
      case 30:
        _handleParseComplete(packet);
        _updated();
        break;
    }
  }

  void _handleDiscoverRsp(Map<int, dynamic> body) {
    final esn = _string(body, 1);
    final nonce = _bytes(body, 2);
    final types = _enumList(body, 3);
    final currentIp = _string(body, 4);
    final mask = _string(body, 5);
    machine.recordDiscovery(esn, nonce, types, currentIp, mask);
    _updated();
  }

  void _handleParseComplete(CpdPacket packet) {
    machine.recordParseComplete(packet.body);
    final client = _message(packet.body, 1);
    final esn = _string(client, 1);
    final types = _enumList(client, 2);
    final result = CpdResult.fromValue(packet.body[2]);
    final ack = CpdPacket(
      sessionId: Uint8List.fromList(packet.sessionId),
      messageId: Uint8List.fromList(packet.messageId),
      bodyField: 31,
      body: {
        1: esn,
        2: CpdPackedEnums(types.map((item) => item.value).toList()),
        3: result.value,
      },
    );
    unawaited(transport.send(ack));
  }

  void _addMissingRanges(Map<int, dynamic> body) {
    final ranges = _messageList(body, 2);
    for (final range in ranges) {
      final start = _int(range, 1);
      final end = _int(range, 2);
      for (var index = start; index <= end; index++) {
        _pendingChunks.add(index);
      }
    }
    final client = _message(body, 1);
    _requesters.add(_string(client, 1));
  }

  Future<void> _sendAll(List<CpdPacket> packets) async {
    for (final packet in packets) {
      await transport.send(packet);
    }
  }

  CpdPacket _packet(int bodyField, Map<int, dynamic> body) {
    return CpdPacket(
      sessionId: machine.sessionId,
      messageId: _uuid(),
      bodyField: bodyField,
      body: body,
    );
  }

  Future<bool> _waitDecision() {
    _decisionCompleter = Completer<bool>();
    _decisionSubscription = discoveryDecision.listen((proceed) {
      if (!_decisionCompleter!.isCompleted) {
        _decisionCompleter!.complete(proceed);
      }
    });
    return _decisionCompleter!.future;
  }

  Future<void> _cleanup() async {
    await _packetSubscription?.cancel();
    await _decisionSubscription?.cancel();
    _packetSubscription = null;
    _decisionSubscription = null;
  }

  bool get _terminal {
    final state = machine.state;
    return state == CpdsActiveState.completed ||
        state == CpdsActiveState.partialSuccess ||
        state == CpdsActiveState.failed;
  }

  void _updated() {
    onUpdate?.call(machine.view());
  }

  bool _sameSession(CpdPacket packet) =>
      _bytesEqual(packet.sessionId, machine.sessionId);
}

Uint8List _uuid() {
  final random = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => random.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  return bytes;
}

List<Uint8List> _chunkBytes(Uint8List data, int chunkSize) {
  final chunks = <Uint8List>[];
  for (var offset = 0; offset < data.length; offset += chunkSize) {
    final end = min(offset + chunkSize, data.length);
    chunks.add(Uint8List.sublistView(data, offset, end));
  }
  return chunks;
}

int _crc32(Uint8List data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _string(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is Uint8List) return String.fromCharCodes(value);
  return value?.toString() ?? '';
}

Uint8List _bytes(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  return Uint8List(0);
}

int _int(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<CpdsDeviceType> _enumList(Map<int, dynamic> map, int field) {
  final value = map[field];
  if (value is CpdPackedEnums) {
    return value.values.map((item) => CpdsDeviceType.fromValue(item)).toList();
  }
  if (value is Uint8List) {
    return _parsePackedVarints(
      value,
    ).map((item) => CpdsDeviceType.fromValue(item)).toList();
  }
  if (value is List) {
    return value.map((item) => CpdsDeviceType.fromValue(item)).toList();
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

Map<int, dynamic> _message(Map<int, dynamic> map, int field) {
  return _asMessage(map[field]) ?? const {};
}

Map<int, dynamic>? _asMessage(Object? value) {
  if (value is Uint8List) return CpdProtocol.parseFields(value);
  if (value is Map<int, dynamic>) return value;
  if (value is Map) return Map<int, dynamic>.from(value);
  return null;
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
