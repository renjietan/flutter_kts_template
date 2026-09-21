import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/selfUpdate/protocol/update_protocol.dart';
import 'package:flutter_kts_template/core/selfUpdate/session/update_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockTransport implements UpdateTransport {
  final sent = <Uint8List>[];
  final _controller = StreamController<Uint8List>.broadcast();
  bool closed = false;
  int _sendCount = 0;

  /// 在第 N 次 send 时返回一条回复（用于确定性模拟“重试后成功”）。
  Uint8List? Function(int sendCount)? onSend;

  @override
  Future<void> send(Uint8List data) async {
    sent.add(data);
    _sendCount++;
    final reply = onSend?.call(_sendCount);
    if (reply != null) {
      _controller.add(reply);
    }
  }

  @override
  Stream<Uint8List> get replies => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emitBytes(Uint8List bytes) => _controller.add(bytes);
}

Uint8List _authAck(String deviceType, String ip) {
  final builder = BytesBuilder()
    ..add('authAck:'.codeUnits)
    ..add(UpdateProtocol.encodeId(deviceType: deviceType, ip: ip));
  return builder.toBytes();
}

void main() {
  test('request returns the first matching reply', () async {
    final transport = _MockTransport();
    final session = UpdateSession(transport: transport);

    final future = session.request<AuthAckReply>(
      command: UpdateProtocol.encodeAuth(),
      timeout: const Duration(seconds: 5),
      matches: (r) => r is AuthAckReply,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    transport.emitBytes(_authAck('CCU', '192.168.1.10'));

    final reply = await future;
    expect(reply?.deviceType, 'CCU');
    expect(reply?.ip, '192.168.1.10');
    expect(transport.sent.length, 1);
  });

  test('request returns null after max attempts on timeout', () async {
    final transport = _MockTransport();
    final session = UpdateSession(transport: transport);

    final reply = await session.request<AuthAckReply>(
      command: UpdateProtocol.encodeAuth(),
      timeout: const Duration(milliseconds: 10),
      matches: (r) => r is AuthAckReply,
      attempts: 3,
    );

    expect(reply, isNull);
    expect(transport.sent.length, 3);
  });

  test('request retries after timeout and succeeds', () async {
    final transport = _MockTransport();
    transport.onSend = (count) =>
        count == 2 ? _authAck('CCU-Audio', '192.168.1.11') : null;
    final session = UpdateSession(transport: transport);

    final reply = await session.request<AuthAckReply>(
      command: UpdateProtocol.encodeAuth(),
      timeout: const Duration(milliseconds: 100),
      matches: (r) => r is AuthAckReply,
      attempts: 3,
    );

    expect(reply?.deviceType, 'CCU-Audio');
    expect(transport.sent.length, 2);
  });

  test('collect returns all matching replies within the window', () async {
    final transport = _MockTransport();
    final session = UpdateSession(transport: transport);

    final future = session.collect<AuthAckReply>(
      command: UpdateProtocol.encodeAuth(),
      timeout: const Duration(milliseconds: 60),
      matches: (r) => r is AuthAckReply,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    transport.emitBytes(_authAck('CCU', '192.168.1.10'));
    transport.emitBytes(_authAck('CCU-Audio', '192.168.1.11'));

    final replies = await future;
    expect(replies.length, 2);
  });

  test('collect retries when the window yields no replies', () async {
    final transport = _MockTransport();
    transport.onSend = (count) =>
        count == 2 ? _authAck('CCU', '192.168.1.10') : null;
    final session = UpdateSession(transport: transport);

    final replies = await session.collect<AuthAckReply>(
      command: UpdateProtocol.encodeAuth(),
      timeout: const Duration(milliseconds: 100),
      matches: (r) => r is AuthAckReply,
    );

    expect(replies.length, 1);
    expect(transport.sent.length, 2);
  });

  test('reset closes transport and prevents further requests', () async {
    final transport = _MockTransport();
    final session = UpdateSession(transport: transport);

    await session.reset();

    expect(transport.closed, isTrue);
    final reply = await session.request<AuthAckReply>(
      command: UpdateProtocol.encodeAuth(),
      timeout: const Duration(milliseconds: 10),
      matches: (r) => r is AuthAckReply,
    );
    expect(reply, isNull);
    expect(transport.sent.length, 0);
  });
}
