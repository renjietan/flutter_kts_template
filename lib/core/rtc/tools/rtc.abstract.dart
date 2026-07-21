import 'dart:typed_data';

import 'rtc.event.dart';

abstract class RtcAbstract {
  Future<List<String>> getRemotePeers();

  Future<void> init(String localPeerAddress);

  Future<void> connect(String remotePeerAddress);

  Future<void> disconnect();

  Future<void> write(Uint8List data, String remotePeerAddress);

  Stream<Uint8List> get receiveStream;

  Stream<RtcEvent> get eventStream;
}
