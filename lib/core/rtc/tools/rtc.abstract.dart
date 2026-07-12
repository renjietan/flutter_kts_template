import 'dart:typed_data';

import 'rtc.event.dart';

abstract class RtcAbstract {
  Future<List<String>> getRemotePeers();

  Future<void> connect(String peerAddress);

  Future<void> disconnect();

  Future<void> write(Uint8List data, String rPeer);

  Stream<Uint8List> get receiveStream;

  Stream<RtcEvent> get eventStream;
}
