import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol_logger.dart';
import 'package:flutter_test/flutter_test.dart';

/// 构造一条「前缀 + ID + 可选尾部」的上行回复。
Uint8List _withId(String prefix, {List<int>? tail}) {
  final builder = BytesBuilder()
    ..add(prefix.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: 'MR9360', ip: '192.168.1.10'));
  if (tail != null) {
    builder.add(tail);
  }
  return builder.toBytes();
}

void main() {
  test('describes Scan outgoing', () {
    final desc = UpdateProtocolLogger.describe(
      UpdateProtocol.encodeScan(),
      outgoing: true,
    );

    expect(
      desc,
      contains('==================== 发送 ============================'),
    );
    expect(desc, contains('总码流：'));
    expect(desc, contains('【指令】：Scan（4 个字节）'));
    expect(desc, contains('0x53, 0x63, 0x61, 0x6e'));
  });

  test('describes auth outgoing', () {
    final desc = UpdateProtocolLogger.describe(
      UpdateProtocol.encodeAuth(),
      outgoing: true,
    );

    expect(desc, contains('【指令】：auth（4 个字节）'));
    expect(desc, contains('0x61, 0x75, 0x74, 0x68'));
  });

  test('describes authAck incoming with source IP and ID', () {
    final desc = UpdateProtocolLogger.describe(
      _withId('authAck:'),
      outgoing: false,
      sourceIp: '192.168.1.10',
    );

    expect(
      desc,
      contains('==================== 接收 - "192.168.1.10" ==============='),
    );
    expect(desc, contains('【指令】：authAck:（8 个字节）'));
    expect(desc, contains('【ID】：MR9360#192.168.1.10'));
  });

  test('describes version_ok incoming with current version tail', () {
    final desc = UpdateProtocolLogger.describe(
      _withId('version_ok:', tail: '1.2.3.4'.codeUnits),
      outgoing: false,
      sourceIp: '192.168.1.10',
    );

    expect(desc, contains('【指令】：version_ok:（11 个字节）'));
    expect(desc, contains('【ID】：MR9360#192.168.1.10'));
    expect(desc, contains('【当前版本】：1.2.3.4（7 个字节）'));
  });

  test('describes file outgoing with all fields', () {
    final desc = UpdateProtocolLogger.describe(
      UpdateProtocol.encodeFile(
        crc32: 0x0a0b0c0d,
        packetCount: 7,
        totalBytes: 1000,
        fileName: 'a.zip',
      ),
      outgoing: true,
    );

    expect(desc, contains('【指令】：file:（5 个字节）'));
    expect(desc, contains('【CRC32（整ZIP）】：168496141（4 个字节）'));
    expect(desc, contains('【包数量】：7（4 个字节）'));
    expect(desc, contains('【文件总字节】：1000（4 个字节）'));
    expect(desc, contains('【文件名称】：a.zip（5 个字节）'));
  });

  test('describes valid outgoing with file header fields', () {
    final desc = UpdateProtocolLogger.describe(
      UpdateProtocol.encodeValid(
        crc32: 0x0a0b0c0d,
        packetCount: 7,
        totalBytes: 1000,
        fileName: 'a.zip',
      ),
      outgoing: true,
    );

    expect(desc, contains('【指令】：valid:（6 个字节）'));
    expect(desc, contains('【CRC32（整ZIP）】：168496141（4 个字节）'));
    expect(desc, contains('【包数量】：7（4 个字节）'));
    expect(desc, contains('【文件总字节】：1000（4 个字节）'));
    expect(desc, contains('【文件名称】：a.zip（5 个字节）'));
  });

  test('describes write outgoing with file header fields', () {
    final desc = UpdateProtocolLogger.describe(
      UpdateProtocol.encodeWrite(
        crc32: 0x0a0b0c0d,
        packetCount: 7,
        totalBytes: 1000,
        fileName: 'a.zip',
      ),
      outgoing: true,
    );

    expect(desc, contains('【指令】：write:（6 个字节）'));
    expect(desc, contains('【文件名称】：a.zip（5 个字节）'));
  });

  test('describes packet outgoing with truncated payload', () {
    // 先记录一次 file: 以让日志知道总包数。
    UpdateProtocolLogger.describe(
      UpdateProtocol.encodeFile(
        crc32: 0x0a0b0c0d,
        packetCount: 10,
        totalBytes: 2000,
        fileName: 'a.zip',
      ),
      outgoing: true,
    );

    // 前 180 字节为 0x00，末尾 20 字节为 0xEE，用于验证「分包数据」只打印前几个字节。
    final payload = Uint8List.fromList([
      ...List<int>.filled(180, 0x00),
      ...List<int>.filled(20, 0xEE),
    ]);
    final desc = UpdateProtocolLogger.describe(
      UpdateProtocol.encodePacket(
        crc32: UpdateProtocol.crc32(payload),
        packetNumber: 3,
        payload: payload,
      ),
      outgoing: true,
    );

    expect(desc, contains('【指令】：packet:（7 个字节）'));
    expect(desc, contains('【包号】：3/10（4 个字节）'));
    expect(desc, contains('【分包长度】：200（4 个字节）'));

    final dataLine = desc.split('\n').firstWhere((l) => l.contains('【分包数据】'));
    expect(dataLine, contains('0x00, 0x00'));
    // 分包数据字段只打印前几个字节，不应出现末尾的 0xee。
    expect(dataLine, isNot(contains('0xee')));
  });

  test('describes packet_fail incoming with reason tail', () {
    UpdateProtocolLogger.describe(
      UpdateProtocol.encodeFile(
        crc32: 0x0a0b0c0d,
        packetCount: 10,
        totalBytes: 2000,
        fileName: 'a.zip',
      ),
      outgoing: true,
    );

    final desc = UpdateProtocolLogger.describe(
      _withId(
        'packet_fail:',
        tail: [
          0x0a, 0x0b, 0x0c, 0x0d, // crc
          0x00, 0x00, 0x00, 0x03, // packet number
          0x00, 0x00, 0x00, 0x0a, // packet length 10
          0x63, 0x72, 0x63, // 'crc'
        ],
      ),
      outgoing: false,
      sourceIp: '192.168.1.10',
    );

    expect(desc, contains('【指令】：packet_fail:（12 个字节）'));
    expect(desc, contains('【ID】：MR9360#192.168.1.10'));
    expect(desc, contains('【包号】：3/10（4 个字节）'));
    expect(desc, contains('【分包长度】：10（4 个字节）'));
    expect(desc, contains('【原因】：crc（3 个字节）'));
  });
}
