import 'dart:typed_data';

import 'package:dage/dage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedPassphrase extends PassphraseProvider {
  final String password;

  _FixedPassphrase(this.password);

  @override
  Future<String> passphrase() async => password;
}

Future<Uint8List> _collect(Stream<List<int>> stream) async {
  final chunks = await stream.toList();
  var total = 0;
  for (final chunk in chunks) {
    total += chunk.length;
  }
  final result = Uint8List(total);
  var offset = 0;
  for (final chunk in chunks) {
    result.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }
  return result;
}

void main() {
  test('dage 口令加密往返（pointycastle 4.0.0 兼容性）', () async {
    final original = Uint8List.fromList(
      List<int>.generate(2048, (i) => i % 256),
    );
    const password = 'UAE@123';

    final encrypted = await _collect(
      encryptWithPassphrase(
        Stream.value(original),
        passphraseProvider: _FixedPassphrase(password),
      ),
    );

    final decrypted = await _collect(
      decryptWithPassphrase(
        Stream.value(encrypted),
        passphraseProvider: _FixedPassphrase(password),
      ),
    );

    expect(encrypted.length, greaterThan(original.length));
    expect(decrypted, original);
  });
}
