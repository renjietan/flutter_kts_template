import 'dart:typed_data';

import 'package:flutter_kts_template/core/cpds/protocol/cpd_protocol.dart';

Future<void> main() async {
  // 回归：同一个 repeated message 字段出现多次时，解码器不能再把单个
  // Uint8List 误当成集合，避免 `_Uint8ArrayView is not a subtype of int`。
  final bindingsField = <int, dynamic>{
    4: [
      {1: 5, 2: 'dc_ccu_main'},
      {1: 8, 2: 'dc_ccu_audio'},
    ],
  };
  final encoded = CpdProtocol.encodeFields(bindingsField);
  final parsed = CpdProtocol.parseFields(encoded);
  final bindings = parsed[4];
  if (bindings is! List || bindings.length != 2) {
    throw StateError('expected 2 repeated bindings, got $bindings');
  }

  // 完整报文 round-trip：AuthRsp 携带两条 DeviceBinding。
  final sessionId = Uint8List.fromList(List<int>.generate(16, (i) => i));
  final messageId = Uint8List.fromList(List<int>.generate(16, (i) => i + 20));
  final packet = CpdPacket(
    sessionId: sessionId,
    messageId: messageId,
    bodyField: 13,
    body: {
      1: {
        1: '123456789012345678901234567890123456789',
        2: CpdPackedEnums([5, 8]),
      },
      2: 1,
      3: 'nn_1',
      4: [
        {1: 5, 2: 'dc_ccu_main'},
        {1: 8, 2: 'dc_ccu_audio'},
      ],
    },
  );
  final datagram = CpdProtocol.encodePacket(packet);
  final decoded = CpdProtocol.decodePacket(datagram);
  if (decoded == null) {
    throw StateError('decode returned null');
  }
  final decodedBindings = decoded.body[4];
  if (decodedBindings is! List || decodedBindings.length != 2) {
    throw StateError('expected 2 decoded bindings, got $decodedBindings');
  }
  for (final raw in decodedBindings) {
    final binding = CpdProtocol.parseFields(raw as Uint8List);
    if (binding[1] == null || binding[2] == null) {
      throw StateError('decoded binding is missing fields: $binding');
    }
  }

  // 单个 length-delimited 字段仍应保持为 Uint8List，不能被误包成 List。
  final single = CpdProtocol.parseFields(
    CpdProtocol.encodeFields({
      3: 'nn_1',
    }),
  );
  if (single[3] is! Uint8List) {
    throw StateError('single length-delimited field should stay Uint8List');
  }

  print('CPD_PROTOCOL_REPEATED_FIELD_OK');
}
