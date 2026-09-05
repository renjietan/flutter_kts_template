import 'dart:typed_data';

enum CpdResult {
  unspecified(0),
  success(1),
  failed(2);

  const CpdResult(this.value);

  final int value;

  static CpdResult fromValue(Object? value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    for (final item in values) {
      if (item.value == parsed) return item;
    }
    return CpdResult.unspecified;
  }
}

enum CpdTransferStage {
  unspecified(0),
  precheck(1),
  cacheReuse(2),
  receive(3),
  verify(4);

  const CpdTransferStage(this.value);

  final int value;

  static CpdTransferStage fromValue(Object? value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    for (final item in values) {
      if (item.value == parsed) return item;
    }
    return CpdTransferStage.unspecified;
  }
}

enum CpdParseStage {
  unspecified(0),
  validate(1),
  extract(2),
  generate(3),
  writeOutput(4),
  snapshot(5),
  skipped(6),
  timeout(7);

  const CpdParseStage(this.value);

  final int value;

  static CpdParseStage fromValue(Object? value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    for (final item in values) {
      if (item.value == parsed) return item;
    }
    return CpdParseStage.unspecified;
  }
}

class CpdPackedEnums {
  CpdPackedEnums(this.values);

  final List<int> values;
}

class CpdFixed32 {
  const CpdFixed32(this.value);

  final int value;
}

class CpdPacket {
  CpdPacket({
    required this.sessionId,
    required this.messageId,
    required this.bodyField,
    required this.body,
  });

  final Uint8List sessionId;
  final Uint8List messageId;
  final int bodyField;
  final Map<int, dynamic> body;
}

class CpdProtocol {
  CpdProtocol._();

  static const int magic = 0xEEDDCCBB;
  static const int magicBytes = 4;
  static const int maxDatagramBytes = 1400;
  static const int maxPacketBytes = maxDatagramBytes - magicBytes;
  static const int chunkSize = 1200;
  static const int cpdcReceivePort = 39001;
  static const int cpdsReceivePort = 39002;

  static Uint8List encodePacket(CpdPacket packet) {
    final writer = _ProtoWriter();
    writer.writeBytes(1, packet.sessionId);
    writer.writeBytes(2, packet.messageId);
    final body = encodeFields(packet.body);
    if (body.length > maxPacketBytes) {
      throw StateError('CPD packet exceeds 1396 bytes');
    }
    writer.writeBytes(packet.bodyField, body);
    final payload = writer.takeBytes();
    final data = Uint8List(magicBytes + payload.length);
    _writeUint32(data, 0, magic);
    data.setRange(magicBytes, data.length, payload);
    if (data.length > maxDatagramBytes) {
      throw StateError('CPD datagram exceeds 1400 bytes');
    }
    return data;
  }

  static CpdPacket? decodePacket(Uint8List data) {
    if (data.length < magicBytes || _readUint32(data, 0) != magic) return null;
    if (data.length > maxDatagramBytes) return null;
    final fields = _ProtoReader.parseFields(
      Uint8List.sublistView(data, magicBytes),
    );
    final sessionId = _bytesValue(fields[1]);
    final messageId = _bytesValue(fields[2]);
    if (sessionId.length != 16 || messageId.length != 16) return null;
    int? bodyField;
    Map<int, dynamic>? body;
    for (final entry in fields.entries) {
      if (entry.key >= 10 && entry.key <= 31) {
        bodyField = entry.key;
        final raw = entry.value;
        body = raw is Uint8List ? _ProtoReader.parseFields(raw) : <int, dynamic>{};
        break;
      }
    }
    if (bodyField == null || body == null) return null;
    return CpdPacket(
      sessionId: Uint8List.fromList(sessionId),
      messageId: Uint8List.fromList(messageId),
      bodyField: bodyField,
      body: body,
    );
  }

  static Uint8List encodeFields(Map<int, dynamic> fields) {
    final writer = _ProtoWriter();
    for (final entry in fields.entries) {
      _writeValue(writer, entry.key, entry.value);
    }
    return writer.takeBytes();
  }

  static Map<int, dynamic> parseFields(Uint8List data) {
    return _ProtoReader.parseFields(data);
  }

  static void _writeValue(_ProtoWriter writer, int field, dynamic value) {
    if (value is int) {
      writer.writeVarint(field, value);
    } else if (value is String) {
      writer.writeBytes(field, Uint8List.fromList(value.codeUnits));
    } else if (value is Uint8List) {
      writer.writeBytes(field, value);
    } else if (value is CpdPackedEnums) {
      final packed = _ProtoWriter();
      for (final item in value.values) {
        packed.writeRawVarint(item);
      }
      writer.writeBytes(field, packed.takeBytes());
    } else if (value is CpdFixed32) {
      writer.writeFixed32(field, value.value);
    } else if (value is List) {
      for (final item in value) {
        _writeValue(writer, field, item);
      }
    } else if (value is Map<int, dynamic>) {
      writer.writeBytes(field, encodeFields(value));
    }
  }

  static Uint8List _bytesValue(Object? value) {
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return Uint8List(0);
  }

  static void _writeUint32(Uint8List data, int offset, int value) {
    final view = ByteData.sublistView(data);
    view.setUint32(offset, value, Endian.big);
  }

  static int _readUint32(Uint8List data, int offset) {
    return ByteData.sublistView(data).getUint32(offset, Endian.big);
  }
}

class _ProtoWriter {
  final BytesBuilder _builder = BytesBuilder();

  void writeVarint(int field, int value) {
    _writeKey(field, 0);
    _writeVarint(value);
  }

  void writeRawVarint(int value) {
    _writeVarint(value);
  }

  void writeFixed32(int field, int value) {
    _writeKey(field, 5);
    final data = Uint8List(4);
    ByteData.sublistView(data).setUint32(0, value, Endian.little);
    _builder.add(data);
  }

  void writeBytes(int field, Uint8List bytes) {
    _writeKey(field, 2);
    _writeVarint(bytes.length);
    _builder.add(bytes);
  }

  Uint8List takeBytes() => _builder.takeBytes();

  void _writeKey(int field, int wireType) {
    _writeVarint((field << 3) | wireType);
  }

  void _writeVarint(int value) {
    var current = value;
    while ((current & ~0x7F) != 0) {
      _builder.addByte((current & 0x7F) | 0x80);
      current = current >>> 7;
    }
    _builder.addByte(current);
  }
}

class _ProtoReader {
  _ProtoReader._();

  static Map<int, dynamic> parseFields(Uint8List data) {
    final result = <int, dynamic>{};
    var offset = 0;
    while (offset < data.length) {
      final key = _readVarint(data, offset);
      final field = key.$1 >> 3;
      final wireType = key.$1 & 0x07;
      offset = key.$2;
      if (wireType == 0) {
        final value = _readVarint(data, offset);
        _addValue(result, field, value.$1);
        offset = value.$2;
      } else if (wireType == 2) {
        final length = _readVarint(data, offset);
        offset = length.$2;
        final value = Uint8List.sublistView(data, offset, offset + length.$1);
        offset += length.$1;
        _addValue(result, field, value);
      } else if (wireType == 5) {
        final value = ByteData.sublistView(data).getUint32(offset, Endian.little);
        offset += 4;
        _addValue(result, field, value);
      } else {
        break;
      }
    }
    return result;
  }

  static void _addValue(Map<int, dynamic> result, int field, dynamic value) {
    final existing = result[field];
    if (existing == null) {
      result[field] = value;
    } else if (existing is List && existing is! Uint8List) {
      // 单个 length-delimited 字段会被存成 Uint8List，而 Uint8List 本身也是
      // List<int>。若只判断 `existing is List`，同一个 repeated 消息字段
      // 出现第二次时会把 Uint8List 误当成“集合”，对其调用 add 一个 Uint8List，
      // 触发 `_Uint8ArrayView is not a subtype of int`。因此这里要排除 Uint8List。
      existing.add(value);
    } else {
      result[field] = <dynamic>[existing, value];
    }
  }

  static (int, int) _readVarint(Uint8List data, int offset) {
    var result = 0;
    var shift = 0;
    while (offset < data.length) {
      final byte = data[offset++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return (result, offset);
  }
}

int cpdEnumValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
