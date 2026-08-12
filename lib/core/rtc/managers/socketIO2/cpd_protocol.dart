import 'dart:math';
import 'dart:typed_data';

import 'cpd_config.dart';
import 'cpd_enums.dart';
import 'cpd_models.dart';

// CRC32/IEEE 计算
class Crc32 {
  static const int _polynomial = 0xEDB88320;
  static List<int>? _table;

  static List<int> _buildTable() {
    if (_table != null) return _table!;
    final table = List<int>.generate(256, (int i) {
      var c = i;
      for (int j = 0; j < 8; j++) {
        c = (c & 1) != 0 ? (_polynomial ^ (c >> 1)) : (c >> 1);
      }
      return c;
    });
    _table = table;
    return table;
  }

  static int compute(Uint8List data) {
    final table = _buildTable();
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc = table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    return (crc ^ 0xFFFFFFFF) >>> 0;
  }
}

// UUID v4 生成
class UuidV4 {
  static final Random _secure = Random.secure();

  static Uint8List generate() {
    final data = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      data[i] = _secure.nextInt(256);
    }
    // 设置 UUID v4 版本位 (0x4x)
    data[6] = (data[6] & 0x0F) | 0x40;
    // 设置 UUID variant 位 (0x8x / 0x9x / 0xAx / 0xBx)
    data[8] = (data[8] & 0x3F) | 0x80;
    return data;
  }
}

// 原始消息体 — 通用容器
class CpdMessage {
  final CpdMessageType type;
  final Map<String, dynamic> fields;

  const CpdMessage(this.type, this.fields);

  // DISCOVER_RSP 字段
  String get esn => fields['esn'] as String? ?? '';
  Uint8List get instanceNonce =>
      fields['instanceNonce'] as Uint8List? ?? Uint8List(0);
  List<String> get deviceTypes =>
      List<String>.from(fields['deviceTypes'] ?? []);
  String get currentIp => fields['currentIp'] as String? ?? '';
  String get subnetMask => fields['subnetMask'] as String? ?? '';

  // AUTH_NTY / AUTH_RSP 字段
  List<AuthAssignment> get assignments =>
      (fields['assignments'] as List<AuthAssignment>?) ?? [];
  List<AuthBinding> get bindings =>
      (fields['bindings'] as List<AuthBinding>?) ?? [];
  ClientIdentity get client =>
      fields['client'] as ClientIdentity? ??
      const ClientIdentity(esn: '', deviceTypes: []);
  Result get result => Result.fromValue(fields['result'] as int? ?? 0);
  String get nodeId => fields['nodeId'] as String? ?? '';
  ErrorCode get errorCode =>
      ErrorCode.fromValue(fields['errorCode'] as int? ?? 0);

  // TRANSFER_START_NTY 字段
  String get fileName => fields['fileName'] as String? ?? '';
  int get fileSize => fields['fileSize'] as int? ?? 0;
  Uint8List get fileSha256 =>
      fields['fileSha256'] as Uint8List? ?? Uint8List(0);
  int get expandedSize => fields['expandedSize'] as int? ?? 0;
  int get requiredWorkspace => fields['requiredWorkspace'] as int? ?? 0;
  int get chunkSize => fields['chunkSize'] as int? ?? 0;
  int get totalChunks => fields['totalChunks'] as int? ?? 0;

  // TRANSFER_CHUNK_NTY 字段
  int get chunkIndex => fields['chunkIndex'] as int? ?? 0;
  Uint8List get payload => fields['payload'] as Uint8List? ?? Uint8List(0);
  int get payloadCrc32 => fields['payloadCrc32'] as int? ?? 0;

  // TRANSFER_PROGRESS_RSP 字段
  int get receivedChunks => fields['receivedChunks'] as int? ?? 0;
  int get percent => fields['percent'] as int? ?? 0;

  // TRANSFER_LOSSPACK_REQ 字段
  List<MissingRange> get missingRanges =>
      (fields['missingRanges'] as List<MissingRange>?) ?? [];

  // TRANSFER_COMPLETE_RSP 字段
  TransferStage get transferStage =>
      TransferStage.fromValue(fields['stage'] as int? ?? 0);

  // PARSE_COMPLETE_REQ 字段
  List<ParseTypeResult> get typeResults =>
      (fields['typeResults'] as List<ParseTypeResult>?) ?? [];

  // PARSE_COMPLETE_ACK 字段
  String get ackEsn => fields['esn'] as String? ?? '';
  List<String> get ackDeviceTypes =>
      List<String>.from(fields['deviceTypes'] ?? []);
}

// Packet 模型
class CpdPacket {
  final Uint8List sessionId;
  final Uint8List messageId;
  final CpdMessage body;

  const CpdPacket({
    required this.sessionId,
    required this.messageId,
    required this.body,
  });
}

// Proto3 编码器
class _ProtoWriter {
  final List<int> _bytes = [];

  void writeVarint(int value) {
    while (value > 0x7F) {
      _bytes.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    _bytes.add(value & 0x7F);
  }

  void writeTag(int fieldNumber, int wireType) {
    writeVarint((fieldNumber << 3) | wireType);
  }

  void writeUint32(int fieldNumber, int value) {
    writeTag(fieldNumber, 0); // varint
    writeVarint(value);
  }

  void writeUint64(int fieldNumber, int value) {
    writeTag(fieldNumber, 0); // varint
    writeVarint(value);
  }

  void writeInt32(int fieldNumber, int value) {
    writeTag(fieldNumber, 0);
    writeVarint(value);
  }

  void writeString(int fieldNumber, String value) {
    final encoded = value.codeUnits;
    writeTag(fieldNumber, 2); // length-delimited
    writeVarint(encoded.length);
    _bytes.addAll(encoded);
  }

  void writeBytes(int fieldNumber, Uint8List value) {
    writeTag(fieldNumber, 2);
    writeVarint(value.length);
    _bytes.addAll(value);
  }

  void writeMessage(int fieldNumber, _ProtoWriter nested) {
    final content = nested.toBytes();
    writeTag(fieldNumber, 2);
    writeVarint(content.length);
    _bytes.addAll(content);
  }

  void writeRepeatedMessage(int fieldNumber, List<_ProtoWriter> items) {
    for (final item in items) {
      writeMessage(fieldNumber, item);
    }
  }

  Uint8List toBytes() => Uint8List.fromList(_bytes);
}

// Proto3 解码器
class _ProtoReader {
  final Uint8List _data;
  int _pos = 0;

  _ProtoReader(this._data);

  bool get hasMore => _pos < _data.length;

  int readVarint() {
    var result = 0;
    var shift = 0;
    while (hasMore) {
      final byte = _data[_pos++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }

  int readUint32() => readVarint();
  int readInt32() => readVarint();

  String readString() {
    final len = readVarint();
    final end = _pos + len;
    if (end > _data.length) {
      _pos = _data.length;
      return '';
    }
    final s = String.fromCharCodes(_data.sublist(_pos, end));
    _pos = end;
    return s;
  }

  Uint8List readBytes() {
    final len = readVarint();
    final end = _pos + len;
    if (end > _data.length) {
      final result = Uint8List.fromList(_data.sublist(_pos));
      _pos = _data.length;
      return result;
    }
    final result = Uint8List.fromList(_data.sublist(_pos, end));
    _pos = end;
    return result;
  }

  _ProtoReader readSubMessage() {
    final len = readVarint();
    final end = _pos + len;
    if (end > _data.length) {
      final result = _ProtoReader(Uint8List.fromList(_data.sublist(_pos)));
      _pos = _data.length;
      return result;
    }
    final result = _ProtoReader(Uint8List.fromList(_data.sublist(_pos, end)));
    _pos = end;
    return result;
  }

  int get position => _pos;
}

// CPD 协议编解码器
class CpdProtocol {
  CpdProtocol._();

  // 编码: Packet → Uint8List (Magic + Proto3)
  static Uint8List encodePacket(CpdPacket packet) {
    final writer = _ProtoWriter();
    writer.writeBytes(1, packet.sessionId);
    writer.writeBytes(2, packet.messageId);
    _writeBody(writer, packet.body);
    final protoBytes = writer.toBytes();

    // 前置 4 字节 Magic (网络字节序)
    final result = Uint8List(4 + protoBytes.length);
    result[0] = 0xEE;
    result[1] = 0xDD;
    result[2] = 0xCC;
    result[3] = 0xBB;
    result.setRange(4, result.length, protoBytes);
    return result;
  }

  static void _writeBody(_ProtoWriter writer, CpdMessage msg) {
    // 空消息体: 写入 tag(field=fn, wire_type=2), length=0
    if (msg.type == CpdMessageType.discoverNty ||
        msg.type == CpdMessageType.transferEndNty) {
      writer.writeTag(msg.type.fieldNumber, 2);
      writer.writeVarint(0);
      return;
    }

    // 非空消息体: 先在子 writer 中写入内容, 再封装 tag + length
    final bodyWriter = _ProtoWriter();
    switch (msg.type) {
      case CpdMessageType.discoverNty:
      case CpdMessageType.transferEndNty:
        break;
      case CpdMessageType.discoverRsp:
        _writeDiscoverRsp(bodyWriter, msg);
        break;
      case CpdMessageType.authNty:
        _writeAuthNty(bodyWriter, msg);
        break;
      case CpdMessageType.authRsp:
        _writeAuthRsp(bodyWriter, msg);
        break;
      case CpdMessageType.transferStartNty:
        _writeTransferStartNty(bodyWriter, msg);
        break;
      case CpdMessageType.transferChunkNty:
        _writeTransferChunkNty(bodyWriter, msg);
        break;
      case CpdMessageType.transferProgressRsp:
        _writeTransferProgressRsp(bodyWriter, msg);
        break;
      case CpdMessageType.transferLosspackReq:
        _writeTransferLosspackReq(bodyWriter, msg);
        break;
      case CpdMessageType.transferCompleteRsp:
        _writeTransferCompleteRsp(bodyWriter, msg);
        break;
      case CpdMessageType.parseCompleteReq:
        _writeParseCompleteReq(bodyWriter, msg);
        break;
      case CpdMessageType.parseCompleteAck:
        _writeParseCompleteAck(bodyWriter, msg);
        break;
    }
    writer.writeMessage(msg.type.fieldNumber, bodyWriter);
  }

  static void _writeDiscoverRsp(_ProtoWriter w, CpdMessage msg) {
    w.writeString(2, msg.esn);
    w.writeBytes(3, msg.instanceNonce);
    for (final dt in msg.deviceTypes) {
      w.writeString(4, dt);
    }
    w.writeString(5, msg.currentIp);
    w.writeString(6, msg.subnetMask);
  }

  static void _writeClientIdentity(
    _ProtoWriter w,
    int fieldNum,
    ClientIdentity client,
  ) {
    final cw = _ProtoWriter();
    cw.writeString(1, client.esn);
    for (final dt in client.deviceTypes) {
      cw.writeString(2, dt);
    }
    w.writeMessage(fieldNum, cw);
  }

  static void _writeAuthNty(_ProtoWriter w, CpdMessage msg) {
    for (final a in msg.assignments) {
      final aw = _ProtoWriter();
      aw.writeUint32(1, a.deviceType.value);
      aw.writeString(2, a.esn);
      aw.writeString(3, a.nodeId);
      aw.writeString(4, a.deviceId);
      w.writeMessage(3, aw);
    }
  }

  static void _writeAuthRsp(_ProtoWriter w, CpdMessage msg) {
    _writeClientIdentity(w, 1, msg.client);
    w.writeUint32(2, msg.result.index);
    w.writeString(3, msg.nodeId);
    for (final b in msg.bindings) {
      final bw = _ProtoWriter();
      bw.writeUint32(1, b.deviceType.value);
      bw.writeString(2, b.nodeId);
      bw.writeString(3, b.deviceId);
      w.writeMessage(4, bw);
    }
    w.writeUint32(5, msg.errorCode.value);
  }

  static void _writeTransferStartNty(_ProtoWriter w, CpdMessage msg) {
    w.writeString(1, msg.fileName);
    w.writeUint64(2, msg.fileSize);
    w.writeBytes(3, msg.fileSha256);
    w.writeUint64(4, msg.expandedSize);
    w.writeUint64(5, msg.requiredWorkspace);
    w.writeUint32(6, msg.chunkSize);
    w.writeUint32(7, msg.totalChunks);
  }

  static void _writeTransferChunkNty(_ProtoWriter w, CpdMessage msg) {
    w.writeUint32(1, msg.chunkIndex);
    w.writeBytes(2, msg.payload);
    w.writeUint32(3, msg.payloadCrc32);
  }

  static void _writeTransferProgressRsp(_ProtoWriter w, CpdMessage msg) {
    _writeClientIdentity(w, 1, msg.client);
    w.writeUint32(2, msg.receivedChunks);
    w.writeUint32(3, msg.totalChunks);
    w.writeUint32(4, msg.percent);
  }

  static void _writeTransferLosspackReq(_ProtoWriter w, CpdMessage msg) {
    _writeClientIdentity(w, 1, msg.client);
    for (final r in msg.missingRanges) {
      final rw = _ProtoWriter();
      rw.writeUint32(1, r.start);
      rw.writeUint32(2, r.end);
      w.writeMessage(2, rw);
    }
  }

  static void _writeTransferCompleteRsp(_ProtoWriter w, CpdMessage msg) {
    _writeClientIdentity(w, 1, msg.client);
    w.writeUint32(2, msg.result.index);
    w.writeUint32(3, msg.transferStage.value);
    w.writeUint32(4, msg.receivedChunks);
    w.writeUint32(5, msg.totalChunks);
    w.writeUint32(6, msg.errorCode.value);
  }

  static void _writeParseCompleteReq(_ProtoWriter w, CpdMessage msg) {
    _writeClientIdentity(w, 1, msg.client);
    w.writeUint32(2, msg.result.index);
    w.writeString(3, msg.nodeId);
    for (final b in msg.bindings) {
      final bw = _ProtoWriter();
      bw.writeUint32(1, b.deviceType.value);
      bw.writeString(2, b.nodeId);
      bw.writeString(3, b.deviceId);
      w.writeMessage(4, bw);
    }
    for (final t in msg.typeResults) {
      final tw = _ProtoWriter();
      tw.writeUint32(1, t.deviceType.value);
      if (t.deviceId != null) tw.writeString(2, t.deviceId!);
      tw.writeUint32(3, t.stage.value);
      tw.writeUint32(4, t.errorCode.value);
      w.writeMessage(5, tw);
    }
    w.writeUint32(6, msg.errorCode.value);
  }

  static void _writeParseCompleteAck(_ProtoWriter w, CpdMessage msg) {
    w.writeString(1, msg.ackEsn);
    for (final dt in msg.ackDeviceTypes) {
      w.writeString(2, dt);
    }
    w.writeUint32(3, msg.result.index);
  }

  // 解码: Uint8List → CpdPacket? (Magic 校验失败返回 null)
  static CpdPacket? decodePacket(Uint8List data) {
    if (data.length < 4) return null;
    if (data[0] != 0xEE ||
        data[1] != 0xDD ||
        data[2] != 0xCC ||
        data[3] != 0xBB) {
      return null;
    }

    final reader = _ProtoReader(Uint8List.fromList(data.sublist(4)));
    Uint8List? sessionId;
    Uint8List? messageId;
    CpdMessage? body;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (fieldNumber) {
        case 1:
          if (wireType == 2) sessionId = reader.readBytes();
          break;
        case 2:
          if (wireType == 2) messageId = reader.readBytes();
          break;
        default:
          // oneof body: field 3-14
          if (fieldNumber >= 3 && fieldNumber <= 14) {
            body = _readBody(reader, fieldNumber, wireType);
          } else {
            // 跳过未知字段
            _skipField(reader, wireType);
          }
          break;
      }
    }

    if (sessionId == null || messageId == null || body == null) return null;
    return CpdPacket(sessionId: sessionId, messageId: messageId, body: body);
  }

  static void _skipField(_ProtoReader reader, int wireType) {
    switch (wireType) {
      case 0: // varint
        reader.readVarint();
        break;
      case 2: // length-delimited
        final len = reader.readVarint();
        reader._pos += len;
        break;
      default:
        break;
    }
  }

  static CpdMessage? _readBody(
    _ProtoReader reader,
    int fieldNumber,
    int wireType,
  ) {
    final type = _fieldNumberToMessageType(fieldNumber);
    if (type == null) {
      _skipField(reader, wireType);
      return null;
    }

    // 对于 wire_type 2 (length-delimited), 先读取长度前缀, 再切出子 reader
    _ProtoReader bodyReader;
    if (wireType == 2) {
      bodyReader = reader.readSubMessage();
    } else {
      bodyReader = reader;
    }

    switch (type) {
      case CpdMessageType.discoverNty:
        return const CpdMessage(CpdMessageType.discoverNty, {});
      case CpdMessageType.discoverRsp:
        return _readDiscoverRsp(bodyReader);
      case CpdMessageType.authNty:
        return _readAuthNty(bodyReader);
      case CpdMessageType.authRsp:
        return _readAuthRsp(bodyReader);
      case CpdMessageType.transferStartNty:
        return _readTransferStartNty(bodyReader);
      case CpdMessageType.transferChunkNty:
        return _readTransferChunkNty(bodyReader);
      case CpdMessageType.transferProgressRsp:
        return _readTransferProgressRsp(bodyReader);
      case CpdMessageType.transferEndNty:
        return const CpdMessage(CpdMessageType.transferEndNty, {});
      case CpdMessageType.transferLosspackReq:
        return _readTransferLosspackReq(bodyReader);
      case CpdMessageType.transferCompleteRsp:
        return _readTransferCompleteRsp(bodyReader);
      case CpdMessageType.parseCompleteReq:
        return _readParseCompleteReq(bodyReader);
      case CpdMessageType.parseCompleteAck:
        return _readParseCompleteAck(bodyReader);
    }
  }

  static CpdMessageType? _fieldNumberToMessageType(int fn) {
    for (final t in CpdMessageType.values) {
      if (t.fieldNumber == fn) return t;
    }
    return null;
  }

  static CpdMessage _readDiscoverRsp(_ProtoReader reader) {
    String esn = '';
    Uint8List nonce = Uint8List(0);
    final deviceTypes = <String>[];
    String ip = '';
    String mask = '';

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) esn = reader.readString();
          break;
        case 2:
          if (wt == 2) nonce = reader.readBytes();
          break;
        case 3:
          if (wt == 2) deviceTypes.add(reader.readString());
          break;
        case 4:
          if (wt == 2) ip = reader.readString();
          break;
        case 5:
          if (wt == 2) mask = reader.readString();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.discoverRsp, {
      'esn': esn,
      'instanceNonce': nonce,
      'deviceTypes': deviceTypes,
      'currentIp': ip,
      'subnetMask': mask,
    });
  }

  static ClientIdentity _readClientIdentity(_ProtoReader reader) {
    String esn = '';
    final deviceTypes = <String>[];

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) esn = reader.readString();
          break;
        case 2:
          if (wt == 2) deviceTypes.add(reader.readString());
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return ClientIdentity(esn: esn, deviceTypes: deviceTypes);
  }

  static CpdMessage _readAuthNty(_ProtoReader reader) {
    final assignments = <AuthAssignment>[];

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      if (fn == 3 && wt == 2) {
        final ar = reader.readSubMessage();
        assignments.add(_readAuthAssignment(ar));
      } else {
        _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.authNty, {'assignments': assignments});
  }

  static AuthAssignment _readAuthAssignment(_ProtoReader reader) {
    DeviceType deviceType = DeviceType.unknown;
    String esn = '';
    String nodeId = '';
    String deviceId = '';

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 0) deviceType = DeviceType.fromValue(reader.readUint32());
          break;
        case 2:
          if (wt == 2) esn = reader.readString();
          break;
        case 3:
          if (wt == 2) nodeId = reader.readString();
          break;
        case 4:
          if (wt == 2) deviceId = reader.readString();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return AuthAssignment(
      deviceType: deviceType,
      esn: esn,
      nodeId: nodeId,
      deviceId: deviceId,
    );
  }

  static AuthBinding _readAuthBinding(_ProtoReader reader) {
    DeviceType deviceType = DeviceType.unknown;
    String nodeId = '';
    String deviceId = '';

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 0) deviceType = DeviceType.fromValue(reader.readUint32());
          break;
        case 2:
          if (wt == 2) nodeId = reader.readString();
          break;
        case 3:
          if (wt == 2) deviceId = reader.readString();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return AuthBinding(
      deviceType: deviceType,
      nodeId: nodeId,
      deviceId: deviceId,
    );
  }

  static CpdMessage _readAuthRsp(_ProtoReader reader) {
    ClientIdentity client = const ClientIdentity(esn: '', deviceTypes: []);
    int resultIdx = 0;
    String nodeId = '';
    final bindings = <AuthBinding>[];
    int errorCodeVal = 0;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) client = _readClientIdentity(reader.readSubMessage());
          break;
        case 2:
          if (wt == 0) resultIdx = reader.readUint32();
          break;
        case 3:
          if (wt == 2) nodeId = reader.readString();
          break;
        case 4:
          if (wt == 2) bindings.add(_readAuthBinding(reader.readSubMessage()));
          break;
        case 5:
          if (wt == 0) errorCodeVal = reader.readUint32();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.authRsp, {
      'client': client,
      'result': resultIdx,
      'nodeId': nodeId,
      'bindings': bindings,
      'errorCode': errorCodeVal,
    });
  }

  static CpdMessage _readTransferStartNty(_ProtoReader reader) {
    String fileName = '';
    int fileSize = 0;
    Uint8List sha256 = Uint8List(0);
    int expandedSize = 0;
    int requiredWorkspace = 0;
    int chunkSize = 0;
    int totalChunks = 0;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) fileName = reader.readString();
          break;
        case 2:
          if (wt == 0) fileSize = reader.readVarint();
          break;
        case 3:
          if (wt == 2) sha256 = reader.readBytes();
          break;
        case 4:
          if (wt == 0) expandedSize = reader.readVarint();
          break;
        case 5:
          if (wt == 0) requiredWorkspace = reader.readVarint();
          break;
        case 6:
          if (wt == 0) chunkSize = reader.readUint32();
          break;
        case 7:
          if (wt == 0) totalChunks = reader.readUint32();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.transferStartNty, {
      'fileName': fileName,
      'fileSize': fileSize,
      'fileSha256': sha256,
      'expandedSize': expandedSize,
      'requiredWorkspace': requiredWorkspace,
      'chunkSize': chunkSize,
      'totalChunks': totalChunks,
    });
  }

  static CpdMessage _readTransferChunkNty(_ProtoReader reader) {
    int chunkIndex = 0;
    Uint8List payload = Uint8List(0);
    int payloadCrc32 = 0;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 0) chunkIndex = reader.readUint32();
          break;
        case 2:
          if (wt == 2) payload = reader.readBytes();
          break;
        case 3:
          if (wt == 0) payloadCrc32 = reader.readUint32();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.transferChunkNty, {
      'chunkIndex': chunkIndex,
      'payload': payload,
      'payloadCrc32': payloadCrc32,
    });
  }

  static CpdMessage _readTransferProgressRsp(_ProtoReader reader) {
    ClientIdentity client = const ClientIdentity(esn: '', deviceTypes: []);
    int receivedChunks = 0;
    int totalChunks = 0;
    int percent = 0;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) client = _readClientIdentity(reader.readSubMessage());
          break;
        case 2:
          if (wt == 0) receivedChunks = reader.readUint32();
          break;
        case 3:
          if (wt == 0) totalChunks = reader.readUint32();
          break;
        case 4:
          if (wt == 0) percent = reader.readUint32();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.transferProgressRsp, {
      'client': client,
      'receivedChunks': receivedChunks,
      'totalChunks': totalChunks,
      'percent': percent,
    });
  }

  static CpdMessage _readTransferLosspackReq(_ProtoReader reader) {
    ClientIdentity client = const ClientIdentity(esn: '', deviceTypes: []);
    final ranges = <MissingRange>[];

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) client = _readClientIdentity(reader.readSubMessage());
          break;
        case 2:
          if (wt == 2) {
            final rr = reader.readSubMessage();
            int start = 0;
            int end = 0;
            while (rr.hasMore) {
              final t = rr.readVarint();
              final f = t >> 3;
              final w = t & 0x7;
              if (f == 1 && w == 0) start = rr.readUint32();
              if (f == 2 && w == 0) end = rr.readUint32();
              _skipField(rr, w);
            }
            ranges.add(MissingRange(start: start, end: end));
          }
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.transferLosspackReq, {
      'client': client,
      'missingRanges': ranges,
    });
  }

  static CpdMessage _readTransferCompleteRsp(_ProtoReader reader) {
    ClientIdentity client = const ClientIdentity(esn: '', deviceTypes: []);
    int resultIdx = 0;
    int stageVal = 0;
    int receivedChunks = 0;
    int totalChunks = 0;
    int errorCodeVal = 0;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) client = _readClientIdentity(reader.readSubMessage());
          break;
        case 2:
          if (wt == 0) resultIdx = reader.readUint32();
          break;
        case 3:
          if (wt == 0) stageVal = reader.readUint32();
          break;
        case 4:
          if (wt == 0) receivedChunks = reader.readUint32();
          break;
        case 5:
          if (wt == 0) totalChunks = reader.readUint32();
          break;
        case 6:
          if (wt == 0) errorCodeVal = reader.readUint32();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.transferCompleteRsp, {
      'client': client,
      'result': resultIdx,
      'stage': stageVal,
      'receivedChunks': receivedChunks,
      'totalChunks': totalChunks,
      'errorCode': errorCodeVal,
    });
  }

  static CpdMessage _readParseCompleteReq(_ProtoReader reader) {
    ClientIdentity client = const ClientIdentity(esn: '', deviceTypes: []);
    int resultIdx = 0;
    String nodeId = '';
    final bindings = <AuthBinding>[];
    final typeResults = <ParseTypeResult>[];
    int errorCodeVal = 0;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) client = _readClientIdentity(reader.readSubMessage());
          break;
        case 2:
          if (wt == 0) resultIdx = reader.readUint32();
          break;
        case 3:
          if (wt == 2) nodeId = reader.readString();
          break;
        case 4:
          if (wt == 2) bindings.add(_readAuthBinding(reader.readSubMessage()));
          break;
        case 5:
          if (wt == 2) {
            final tr = reader.readSubMessage();
            typeResults.add(_readParseTypeResult(tr));
          }
          break;
        case 6:
          if (wt == 0) errorCodeVal = reader.readUint32();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.parseCompleteReq, {
      'client': client,
      'result': resultIdx,
      'nodeId': nodeId,
      'bindings': bindings,
      'typeResults': typeResults,
      'errorCode': errorCodeVal,
    });
  }

  static ParseTypeResult _readParseTypeResult(_ProtoReader reader) {
    DeviceType deviceType = DeviceType.unknown;
    String? deviceId;
    ParseStage stage = ParseStage.unspecified;
    ErrorCode errorCode = ErrorCode.unspecified;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 0) deviceType = DeviceType.fromValue(reader.readUint32());
          break;
        case 2:
          if (wt == 2) deviceId = reader.readString();
          break;
        case 3:
          if (wt == 0) stage = ParseStage.fromValue(reader.readUint32());
          break;
        case 4:
          if (wt == 0) errorCode = ErrorCode.fromValue(reader.readUint32());
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return ParseTypeResult(
      deviceType: deviceType,
      deviceId: deviceId,
      stage: stage,
      errorCode: errorCode,
    );
  }

  static CpdMessage _readParseCompleteAck(_ProtoReader reader) {
    String esn = '';
    final deviceTypes = <String>[];
    int resultIdx = 0;

    while (reader.hasMore) {
      final tag = reader.readVarint();
      final fn = tag >> 3;
      final wt = tag & 0x7;
      switch (fn) {
        case 1:
          if (wt == 2) esn = reader.readString();
          break;
        case 2:
          if (wt == 2) deviceTypes.add(reader.readString());
          break;
        case 3:
          if (wt == 0) resultIdx = reader.readUint32();
          break;
        default:
          _skipField(reader, wt);
      }
    }

    return CpdMessage(CpdMessageType.parseCompleteAck, {
      'esn': esn,
      'deviceTypes': deviceTypes,
      'result': resultIdx,
    });
  }

  // 计算编码后的大小
  static int estimatePacketSize(CpdPacket packet) {
    // 简化估算：Magic(4) + sessionId(2+16) + messageId(2+16) + body
    return 4 + 18 + 18 + 200; // 粗略估算
  }

  // 检查消息体编码后是否超过限制
  static bool isPacketTooLarge(CpdPacket packet) {
    final encoded = encodePacket(packet);
    return encoded.length > CpdConfig.maxUdpPayload;
  }
}
