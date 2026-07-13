import 'dart:typed_data';

class ByteTools {
  static const Endian defaultEndian = Endian.big;
  static const int defaultUnitSize = 1;
  static Uint8List int2UintList(
    int value, {
    required int byteLen,
    Endian? endian = defaultEndian,
  }) {
    ByteData data = ByteData(byteLen);
    switch (byteLen) {
      case 1:
        data.setUint8(0, value);
        break;
      case 2:
        data.setUint16(0, value, endian!);
        break;
      case 4:
        data.setUint32(0, value, endian!);
        break;
      case 8:
        data.setUint64(0, value, endian!);
        break;
    }
    return data.buffer.asUint8List();
  }

  static int uIntList2Int(
    Uint8List, {
    required int byteLen,
    Endian? endian = defaultEndian,
  }) {
    ByteData data = ByteData.sublistView(Uint8List);
    int res = 0;
    switch (byteLen) {
      case 1:
        res = data.getInt8(0);
        break;
      case 2:
        res = data.getUint16(0, endian!);
        break;
      case 4:
        res = data.getUint32(0, endian!);
        break;
      case 8:
        res = data.getUint64(0, endian!);
        break;
    }
    return res;
  }

  static Uint8List str2UintList(
    String text, {
    Endian? endian = defaultEndian,
    int? unitSize = defaultUnitSize,
  }) {
    if (![1, 2, 4, 8].contains(unitSize)) {
      throw ArgumentError('unitSize 必须为 1、2、4 或 8');
    }
    List<int> codeUnits = text.codeUnits;
    ByteData byteData = ByteData(codeUnits.length * unitSize!);
    for (int i = 0; i < codeUnits.length; i++) {
      switch (unitSize) {
        case 1:
          byteData.setUint8(i * unitSize, codeUnits[i]);
          break;
        case 2:
          byteData.setUint16(i * unitSize, codeUnits[i], endian!);
          break;
        case 4:
          byteData.setUint32(i * unitSize, codeUnits[i], endian!);
          break;
        case 8:
          byteData.setUint64(i * unitSize, codeUnits[i], endian!);
          break;
      }
    }
    Uint8List res = byteData.buffer.asUint8List();
    return res;
  }

  static String uIntList2str(
    Uint8List bytes, {
    Endian endian = defaultEndian,
    int unitSize = defaultUnitSize,
  }) {
    if (![1, 2, 4, 8].contains(unitSize)) {
      throw ArgumentError('unitSize 必须为 1、2、4 或 8');
    }
    if (bytes.length % unitSize != 0) {
      throw ArgumentError('字节数组长度必须是 unitSize 的整数倍');
    }

    final byteData = ByteData.sublistView(bytes);
    final codeUnits = <int>[];

    switch (unitSize) {
      case 1:
        for (int i = 0; i < bytes.length; i += 1) {
          codeUnits.add(byteData.getUint8(i));
        }
        break;
      case 2:
        for (int i = 0; i < bytes.length; i += 2) {
          codeUnits.add(byteData.getUint16(i, endian));
        }
        break;
      case 4:
        for (int i = 0; i < bytes.length; i += 4) {
          codeUnits.add(byteData.getUint32(i, endian));
        }
        break;
      case 8:
        for (int i = 0; i < bytes.length; i += 8) {
          codeUnits.add(byteData.getUint64(i, endian));
        }
        break;
    }
    return String.fromCharCodes(codeUnits);
  }

  static String uIntList2uIntListStr(Uint8List data) {
    String bytesStr;
    bytesStr = data.fold("[", (cur, pre) {
      cur = cur + '0x${pre.toRadixString(16).padLeft(2, '0')}' + ",";
      return cur;
    });
    bytesStr = bytesStr + "]";
    return bytesStr;
  }

  static void modifyByteByRange(
    Uint8List data,
    int start,
    int end,
    Uint8List value,
  ) {
    if (start < 0 || end >= data.length || start > end) {
      throw RangeError('索引越界: 有效范围 0~${data.length - 1}');
    }
    if (value.length != (end - start)) {
      throw ArgumentError('newValues 的长度必须与修改范围的长度一致');
    }
    data.setRange(start, end, value);
  }

  static List<Uint8List> chunkBytes(Uint8List data, {int chunkSize = 500}) {
    List<Uint8List> chunks = [];
    for (int i = 0; i < data.length; i += chunkSize) {
      int end = i + chunkSize;
      if (end > data.length) end = data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }
}
