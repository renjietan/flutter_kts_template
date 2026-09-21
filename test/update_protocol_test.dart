import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List bytes(List<int> values) => Uint8List.fromList(values);

/// 构造一条「前缀 + ID + 尾部」的上行回复。
Uint8List reply(
  String prefix, {
  String deviceType = 'MR9360',
  String ip = '192.168.1.10',
  List<int>? trailing,
}) {
  final builder = BytesBuilder();
  builder.add(prefix.codeUnits);
  builder.add(UpdateProtocol.encodeId(deviceType: deviceType, ip: ip));
  if (trailing != null) {
    builder.add(trailing);
  }
  return builder.toBytes();
}

void main() {
  group('encode commands', () {
    test('scan/auth/version encode as ascii', () {
      expect(String.fromCharCodes(UpdateProtocol.encodeScan()), 'Scan');
      expect(String.fromCharCodes(UpdateProtocol.encodeAuth()), 'auth');
      expect(
        String.fromCharCodes(UpdateProtocol.encodeVersion('0.1.1.1')),
        'version:0.1.1.1',
      );
    });

    test('file encodes crc32 first then big-endian counts and filename', () {
      final data = UpdateProtocol.encodeFile(
        crc32: 0x0a0b0c0d,
        packetCount: 0x01020304,
        totalBytes: 0x05060708,
        fileName: 'a.zip',
      );

      expect(data.length, 5 + 12 + 5);
      expect(String.fromCharCodes(data.sublist(0, 5)), 'file:');
      final view = ByteData.sublistView(data);
      expect(view.getUint32(5, Endian.big), 0x0a0b0c0d);
      expect(view.getUint32(9, Endian.big), 0x01020304);
      expect(view.getUint32(13, Endian.big), 0x05060708);
      expect(String.fromCharCodes(data.sublist(17)), 'a.zip');
    });

    test('packet encodes crc32 then big-endian number and length plus payload', () {
      final payload = Uint8List.fromList([1, 2, 3, 4]);
      final data = UpdateProtocol.encodePacket(
        crc32: 0x0a0b0c0d,
        packetNumber: 7,
        payload: payload,
      );

      expect(data.length, 7 + 12 + 4);
      expect(String.fromCharCodes(data.sublist(0, 7)), 'packet:');
      final view = ByteData.sublistView(data);
      expect(view.getUint32(7, Endian.big), 0x0a0b0c0d);
      expect(view.getUint32(11, Endian.big), 7);
      expect(view.getUint32(15, Endian.big), 4);
      expect(data.sublist(19), payload);
    });
  });

  group('encodeId', () {
    test('uses big-endian lengths with type then ip', () {
      final id = UpdateProtocol.encodeId(
        deviceType: 'MR9360',
        ip: '192.168.1.10',
      );

      expect(id.length, 2 + 6 + 2 + 12);
      expect(id.sublist(0, 2), [0x00, 0x06]);
      expect(String.fromCharCodes(id.sublist(2, 8)), 'MR9360');
      expect(id.sublist(8, 10), [0x00, 0x0C]);
      expect(String.fromCharCodes(id.sublist(10)), '192.168.1.10');
    });
  });

  group('parse replies', () {
    test('scan success', () {
      expect(
        UpdateProtocol.parseReply(bytes('Scan:success'.codeUnits)),
        isA<ScanAckReply>(),
      );
    });

    test('authAck parses id', () {
      final r = UpdateProtocol.parseReply(reply('authAck:')) as AuthAckReply;
      expect(r.deviceType, 'MR9360');
      expect(r.ip, '192.168.1.10');
    });

    test('version_ok parses id and version', () {
      final r = UpdateProtocol.parseReply(
        reply('version_ok:', trailing: '0.1.1.1'.codeUnits),
      ) as VersionOkReply;
      expect(r.deviceType, 'MR9360');
      expect(r.ip, '192.168.1.10');
      expect(r.version, '0.1.1.1');
    });

    test('version_fail parses id and reason', () {
      final r = UpdateProtocol.parseReply(
        reply('version_fail:', trailing: 'format'.codeUnits),
      ) as VersionFailReply;
      expect(r.deviceType, 'MR9360');
      expect(r.ip, '192.168.1.10');
      expect(r.reason, 'format');
    });

    test('fileAck parses id and binary big-endian fields', () {
      final trailing = BytesBuilder()
        ..add([0x0a, 0x0b, 0x0c, 0x0d]) // crc32
        ..add([0x00, 0x00, 0x00, 0x0a]) // packetCount 10
        ..add([0x00, 0x00, 0x03, 0xe8]) // totalBytes 1000
        ..add('a.zip'.codeUnits);
      final r = UpdateProtocol.parseReply(
        reply('fileAck:', trailing: trailing.toBytes()),
      ) as FileAckReply;

      expect(r.deviceType, 'MR9360');
      expect(r.ip, '192.168.1.10');
      expect(r.crc32, 0x0a0b0c0d);
      expect(r.packetCount, 10);
      expect(r.totalBytes, 1000);
      expect(r.fileName, 'a.zip');
    });

    test('packetOk parses id, crc32, packet number, and length', () {
      final trailing = BytesBuilder()
        ..add([0x0a, 0x0b, 0x0c, 0x0d]) // crc32
        ..add([0x00, 0x00, 0x00, 0x2a]) // packetNumber 42
        ..add([0x00, 0x00, 0x01, 0x38]); // packetLength 312
      final r = UpdateProtocol.parseReply(
        reply('packet_ok:', trailing: trailing.toBytes()),
      ) as PacketOkReply;
      expect(r.deviceType, 'MR9360');
      expect(r.ip, '192.168.1.10');
      expect(r.crc32, 0x0a0b0c0d);
      expect(r.packetNumber, 42);
      expect(r.packetLength, 312);
    });

    test('packetFail parses id, crc32, number, length, and reason', () {
      final trailing = BytesBuilder()
        ..add([0x0a, 0x0b, 0x0c, 0x0d]) // crc32
        ..add([0x00, 0x00, 0x00, 0x2a]) // packetNumber 42
        ..add([0x00, 0x00, 0x01, 0x38]) // packetLength 312
        ..add('crc'.codeUnits); // reason
      final r = UpdateProtocol.parseReply(
        reply('packet_fail:', trailing: trailing.toBytes()),
      ) as PacketFailReply;
      expect(r.deviceType, 'MR9360');
      expect(r.ip, '192.168.1.10');
      expect(r.crc32, 0x0a0b0c0d);
      expect(r.packetNumber, 42);
      expect(r.packetLength, 312);
      expect(r.reason, 'crc');
    });

    test('valid ok and fail', () {
      final ok = UpdateProtocol.parseReply(
        reply('valid_ok:'),
      ) as ValidReply;
      expect(ok.ok, isTrue);
      expect(ok.deviceType, 'MR9360');
      expect(ok.reason, isNull);

      final fail = UpdateProtocol.parseReply(
        reply('valid_fail:', trailing: 'crc'.codeUnits),
      ) as ValidReply;
      expect(fail.ok, isFalse);
      expect(fail.reason, 'crc');
    });

    test('update ok and fail', () {
      final ok = UpdateProtocol.parseReply(
        reply('update_ok:', trailing: '0.1.1.1'.codeUnits),
      ) as UpdateResultReply;
      expect(ok.ok, isTrue);
      expect(ok.detail, '0.1.1.1');

      final fail = UpdateProtocol.parseReply(
        reply('update_fail:', trailing: 'timeout'.codeUnits),
      ) as UpdateResultReply;
      expect(fail.ok, isFalse);
      expect(fail.detail, 'timeout');
    });

    test('unknown payload returns null', () {
      expect(UpdateProtocol.parseReply(bytes('garbage'.codeUnits)), isNull);
    });
  });

  test('crc32 matches standard CRC-32 for known input', () {
    expect(UpdateProtocol.crc32('123456789'.codeUnits), 0xcbf43926);
  });
}
