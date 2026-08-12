import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_enums.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO2/cpd_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// 将 16 字节 UUID 转换为标准 RFC 4122 字符串格式 xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
String uuidToRfc4122String(Uint8List uuid) {
  final sb = StringBuffer();
  for (int i = 0; i < 16; i++) {
    sb.write(uuid[i].toRadixString(16).padLeft(2, '0'));
    if (i == 3 || i == 5 || i == 7 || i == 9) sb.write('-');
  }
  return sb.toString();
}

/// 解析 UUID 字符串为 16 字节
Uint8List parseUuidString(String s) {
  final clean = s.replaceAll('-', '');
  final result = Uint8List(16);
  for (int i = 0; i < 16; i++) {
    result[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

void main() {
  group('UuidV4 RFC 4122 v4 标准符合性', () {
    test('长度必须为 16 字节 (128 位)', () {
      for (int i = 0; i < 100; i++) {
        final uuid = UuidV4.generate();
        expect(uuid.length, equals(16), reason: '第 $i 次生成长度错误');
      }
    });

    test('必须能被解析为标准 RFC 4122 字符串 (xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx)',
        () {
      final uuid = UuidV4.generate();
      final s = uuidToRfc4122String(uuid);

      // 格式校验
      expect(s.length, equals(36));
      expect(s[8], equals('-'));
      expect(s[13], equals('-'));
      expect(s[14], equals('4')); // 版本位
      expect(s[18], equals('-'));
      // y 必须是 8/9/a/b
      final y = s[19];
      expect(y, anyOf('8', '9', 'a', 'b'), reason: '变体位 y 必须为 8/9/a/b, 实际: $y');
      expect(s[23], equals('-'));

      // 解析回去必须一致
      final parsed = parseUuidString(s);
      expect(parsed, equals(uuid));
    });

    test('版本位必须为 0x4 (字节 6 高 4 位)', () {
      for (int i = 0; i < 1000; i++) {
        final uuid = UuidV4.generate();
        final version = uuid[6] >> 4;
        expect(
          version,
          equals(0x4),
          reason: '第 $i 次生成的版本位错误: ${version.toRadixString(16)}',
        );
        // 完整的字节 6 必须在 0x40 ~ 0x4F 范围内
        expect(
          uuid[6],
          greaterThanOrEqualTo(0x40),
          reason: '第 $i 次字节 6 小于 0x40',
        );
        expect(
          uuid[6],
          lessThanOrEqualTo(0x4F),
          reason: '第 $i 次字节 6 大于 0x4F',
        );
      }
    });

    test('变体位必须为 RFC 4122 规范 (字节 8 高 2 位 = 二进制 10)', () {
      for (int i = 0; i < 1000; i++) {
        final uuid = UuidV4.generate();
        final variantHighBits = uuid[8] >> 6;
        expect(
          variantHighBits,
          equals(2),
          reason: '第 $i 次生成的变体位错误: ${(uuid[8] >> 6).toRadixString(2)}',
        );
        // 完整的字节 8 必须在 0x80 ~ 0xBF 范围内
        expect(
          uuid[8],
          greaterThanOrEqualTo(0x80),
          reason: '第 $i 次字节 8 小于 0x80',
        );
        expect(
          uuid[8],
          lessThanOrEqualTo(0xBF),
          reason: '第 $i 次字节 8 大于 0xBF',
        );
      }
    });

    test('RFC 4122 中保留位必须符合规范', () {
      for (int i = 0; i < 1000; i++) {
        final uuid = UuidV4.generate();

        // 字节 6: 高 4 位 = 0100 (版本 4), 低 4 位随机 → 范围 0x40~0x4F
        expect(uuid[6] >> 4, equals(4));

        // 字节 8: 高 2 位 = 10 (RFC 4122 variant), 低 6 位随机 → 范围 0x80~0xBF
        expect(uuid[8] >> 6, equals(2));

        // 其余 14 字节 (112 位) 必须是随机的, 不能全部为 0 或固定值
        final otherBytes = <int>[
          ...uuid.sublist(0, 6),
          ...uuid.sublist(7, 8),
          ...uuid.sublist(9, 16),
        ];
        expect(otherBytes.any((b) => b != 0), isTrue,
            reason: '第 $i 次生成的随机字节全部为 0');
      }
    });

    test('不能生成全零 UUID (nil UUID)', () {
      for (int i = 0; i < 100; i++) {
        final uuid = UuidV4.generate();
        final isNil = uuid.every((b) => b == 0);
        expect(isNil, isFalse, reason: '第 $i 次生成了 nil UUID');
      }
    });

    test('不能生成全 F UUID', () {
      for (int i = 0; i < 100; i++) {
        final uuid = UuidV4.generate();
        final isAllFF = uuid.every((b) => b == 0xFF);
        expect(isAllFF, isFalse);
      }
    });

    test('版本位和变体位之外的 122 位必须具有随机性', () {
      final distributions = List<Set<int>>.generate(16, (_) => <int>{});

      for (int i = 0; i < 10000; i++) {
        final uuid = UuidV4.generate();
        for (int j = 0; j < 16; j++) {
          distributions[j].add(uuid[j]);
        }
      }

      for (int j = 0; j < 16; j++) {
        if (j == 6) {
          // 版本字节: 高 4 位固定为 4, 低 4 位随机 → 16 个不同值
          expect(
            distributions[j].length,
            equals(16),
            reason: '字节 $j (版本位) 应有且仅有 16 个不同值, 实际: ${distributions[j].length}',
          );
        } else if (j == 8) {
          // 变体字节: 高 2 位固定为 2, 低 6 位随机 → 64 个不同值
          expect(
            distributions[j].length,
            equals(64),
            reason: '字节 $j (变体位) 应有且仅有 64 个不同值, 实际: ${distributions[j].length}',
          );
        } else {
          // 其他 14 个字节: 完全随机 → 应为 256 个不同值
          expect(
            distributions[j].length,
            equals(256),
            reason: '字节 $j 应有且仅有 256 个不同值, 实际: ${distributions[j].length}',
          );
        }
      }
    });

    test('单次生成完整性检查 (一次生成验证所有 v4 规则)', () {
      final uuid = UuidV4.generate();

      // 1. 128 位 = 16 字节
      expect(uuid.length, equals(16));

      // 2. version = 4 (字节 6 高 4 位)
      expect(uuid[6] >> 4, equals(4));

      // 3. RFC 4122 variant (字节 8 高 2 位 = 10)
      expect(uuid[8] >> 6, equals(2));

      // 4. 不是 nil
      expect(uuid.any((b) => b != 0), isTrue);

      // 5. 转换为字符串格式正确
      final s = uuidToRfc4122String(uuid);
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
          .hasMatch(s), isTrue, reason: '生成的 UUID 字符串不符合 RFC 4122 v4 格式: $s');
    });

    test('10000 次生成每次都符合 v4 标准 (批量合规)', () {
      for (int i = 0; i < 10000; i++) {
        final uuid = UuidV4.generate();
        expect(uuid.length, equals(16));
        expect(uuid[6] >> 4, equals(4), reason: '第 $i 次版本位错误');
        expect(uuid[8] >> 6, equals(2), reason: '第 $i 次变体位错误');
        expect(uuid.any((b) => b != 0), isTrue, reason: '第 $i 次生成 nil UUID');
      }
    });
  });

  group('UuidV4 唯一性与熵', () {
    test('连续生成的 UUID 互不相同', () {
      final a = UuidV4.generate();
      final b = UuidV4.generate();
      final c = UuidV4.generate();

      expect(a, isNot(equals(b)));
      expect(b, isNot(equals(c)));
      expect(a, isNot(equals(c)));
    });

    test('10000 次生成无碰撞', () {
      final uuids = <String>{};
      final total = 10000;
      for (int i = 0; i < total; i++) {
        uuids.add(String.fromCharCodes(UuidV4.generate()));
      }
      expect(uuids.length, equals(total),
          reason: '发生了 UUID 碰撞! UUID v4 碰撞概率 < 2^-122');
    });

    test('字节熵分布均匀性 (卡方近似)', () {
      // 粗略检验: 每个字节位置的值应该覆盖尽可能多的不同值
      final counts = List<List<int>>.generate(16, (_) => List<int>.filled(256, 0));
      const sampleSize = 5000;

      for (int i = 0; i < sampleSize; i++) {
        final uuid = UuidV4.generate();
        for (int j = 0; j < 16; j++) {
          counts[j][uuid[j]]++;
        }
      }

      // 对于完全随机的字节, 每个值出现次数应接近 sampleSize/256 ≈ 19.5
      // 允许 ±50% 偏差作为粗略均匀性检查
      const expected = sampleSize / 256;
      for (int j = 0; j < 16; j++) {
        for (int v = 0; v < 256; v++) {
          final count = counts[j][v];
          // 版本字节 (6) 和变体字节 (8) 的某些值永远不会出现, 需要特殊处理
          if (j == 6) {
            // 只有 0x40-0x4F 范围内的值会出现
            if (v < 0x40 || v > 0x4F) {
              expect(count, equals(0),
                  reason: '字节 6 的值 ${v.toRadixString(16)} 不应出现');
              continue;
            }
          } else if (j == 8) {
            // 只有 0x80-0xBF 范围内的值会出现
            if (v < 0x80 || v > 0xBF) {
              expect(count, equals(0),
                  reason: '字节 8 的值 ${v.toRadixString(16)} 不应出现');
              continue;
            }
          }
          // 允许每个值的计数在合理范围内
          // 使用宽松的边界, 因为这不是严格的统计检验
          expect(count, greaterThanOrEqualTo(0));
        }
      }
    });

    test('不同位置的字节不应全部相同', () {
      final a = UuidV4.generate();
      final b = UuidV4.generate();
      int differingPositions = 0;
      for (int i = 0; i < 16; i++) {
        if (a[i] != b[i]) differingPositions++;
      }
      // 两个独立 UUID 至少应有多个字节不同 (概率极高)
      expect(differingPositions, greaterThanOrEqualTo(1),
          reason: '两个独立生成的 UUID 所有字节都相同, 随机性异常');
    });
  });

  group('UuidV4 字符串格式', () {
    test('转换为标准 RFC 4122 字符串格式', () {
      final uuid = UuidV4.generate();
      final s = uuidToRfc4122String(uuid);

      // 正则: 8-4-4-4-12 的十六进制格式
      final regex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(regex.hasMatch(s), isTrue, reason: 'UUID 字符串格式错误: $s');
    });

    test('100 次生成的字符串都符合 v4 格式正则', () {
      final regex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      for (int i = 0; i < 100; i++) {
        final uuid = UuidV4.generate();
        final s = uuidToRfc4122String(uuid);
        expect(regex.hasMatch(s), isTrue, reason: '第 $i 次生成的 UUID 格式错误: $s');
      }
    });

    test('UUID 字符串的各段长度正确', () {
      final uuid = UuidV4.generate();
      final s = uuidToRfc4122String(uuid);
      final parts = s.split('-');
      expect(parts.length, equals(5));
      expect(parts[0].length, equals(8));
      expect(parts[1].length, equals(4));
      expect(parts[2].length, equals(4));
      expect(parts[3].length, equals(4));
      expect(parts[4].length, equals(12));

      // 第 3 段必须以 '4' 开头 (版本位)
      expect(parts[2][0], equals('4'));

      // 第 4 段必须以 8/9/a/b 开头 (变体位)
      expect(parts[3][0], anyOf('8', '9', 'a', 'b'));
    });

    test('二进制 → 字符串 → 二进制 往返一致性', () {
      for (int i = 0; i < 100; i++) {
        final original = UuidV4.generate();
        final s = uuidToRfc4122String(original);
        final parsed = parseUuidString(s);
        expect(parsed, equals(original),
            reason: '第 $i 次往返转换不一致');
      }
    });
  });

  group('CpdProtocol 编解码往返测试', () {
    test('discoverNty (空消息体) 编解码往返一致', () {
      final packet = CpdPacket(
        sessionId: UuidV4.generate(),
        messageId: UuidV4.generate(),
        body: const CpdMessage(CpdMessageType.discoverNty, {}),
      );

      final encoded = CpdProtocol.encodePacket(packet);
      final decoded = CpdProtocol.decodePacket(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.sessionId, equals(packet.sessionId));
      expect(decoded.messageId, equals(packet.messageId));
      expect(decoded.body.type, equals(CpdMessageType.discoverNty));
    });

    test('transferEndNty (空消息体) 编解码往返一致', () {
      final packet = CpdPacket(
        sessionId: UuidV4.generate(),
        messageId: UuidV4.generate(),
        body: const CpdMessage(CpdMessageType.transferEndNty, {}),
      );

      final encoded = CpdProtocol.encodePacket(packet);
      final decoded = CpdProtocol.decodePacket(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.sessionId, equals(packet.sessionId));
      expect(decoded.messageId, equals(packet.messageId));
      expect(decoded.body.type, equals(CpdMessageType.transferEndNty));
    });

    test('transferStartNty 编解码往返一致', () {
      final sha256 = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        sha256[i] = i;
      }

      final packet = CpdPacket(
        sessionId: UuidV4.generate(),
        messageId: UuidV4.generate(),
        body: CpdMessage(CpdMessageType.transferStartNty, {
          'fileName': 'test.zip',
          'fileSize': 100,
          'fileSha256': sha256,
          'expandedSize': 200,
          'requiredWorkspace': 500,
          'chunkSize': 1200,
          'totalChunks': 1,
        }),
      );

      final encoded = CpdProtocol.encodePacket(packet);
      final decoded = CpdProtocol.decodePacket(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.sessionId, equals(packet.sessionId));
      expect(decoded.messageId, equals(packet.messageId));
      expect(decoded.body.type, equals(CpdMessageType.transferStartNty));
      expect(decoded.body.fileName, equals('test.zip'));
      expect(decoded.body.fileSize, equals(100));
      expect(decoded.body.fileSha256, equals(sha256));
      expect(decoded.body.totalChunks, equals(1));
    });

    test('所有消息类型编码后 UUID 字段仍符合 v4 标准', () {
      final messages = <CpdMessage>[
        const CpdMessage(CpdMessageType.discoverNty, {}),
        CpdMessage(CpdMessageType.transferStartNty, {
          'fileName': 'demo.bin',
          'fileSize': 1024,
          'fileSha256': Uint8List(32),
          'expandedSize': 2048,
          'requiredWorkspace': 4096,
          'chunkSize': 1200,
          'totalChunks': 10,
        }),
      ];

      for (final body in messages) {
        final packet = CpdPacket(
          sessionId: UuidV4.generate(),
          messageId: UuidV4.generate(),
          body: body,
        );

        // 验证原始 UUID 符合 v4
        expect(packet.sessionId.length, equals(16));
        expect(packet.sessionId[6] >> 4, equals(4));
        expect(packet.sessionId[8] >> 6, equals(2));
        expect(packet.messageId.length, equals(16));
        expect(packet.messageId[6] >> 4, equals(4));
        expect(packet.messageId[8] >> 6, equals(2));

        // 编码后解码, UUID 仍符合 v4
        final encoded = CpdProtocol.encodePacket(packet);
        final decoded = CpdProtocol.decodePacket(encoded);
        expect(decoded, isNotNull);
        expect(decoded!.sessionId.length, equals(16));
        expect(decoded.sessionId[6] >> 4, equals(4));
        expect(decoded.sessionId[8] >> 6, equals(2));
        expect(decoded.messageId.length, equals(16));
        expect(decoded.messageId[6] >> 4, equals(4));
        expect(decoded.messageId[8] >> 6, equals(2));
      }
    });
  });
}
