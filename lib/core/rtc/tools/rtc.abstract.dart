import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';

import 'rtc.event.dart';

abstract class RtcAbstract {
  Future<List<String>> getRemotePeers();

  Future<void> init(String localPeerAddress);

  Future<void> connect(String remotePeerAddress);

  Future<void> disconnect();

  Future<void> write(Uint8List data, String remotePeerAddress);

  Stream<RtcReceive> get receiveStream;

  Stream<RtcEvent> get eventStream;
}
