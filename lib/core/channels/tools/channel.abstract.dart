import 'dart:typed_data';

import 'channel.event.dart';

abstract class ChannelAbstract {
  Future<List<String>> getDevices();

  Future<void> connect(String rPeer);

  Future<void> disconnect();

  Future<void> write(Uint8List data);

  Stream<Uint8List> get receiveStream;

  Stream<ChannelEvent> get eventStream;
}
