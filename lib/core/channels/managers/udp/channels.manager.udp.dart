import 'dart:typed_data';

import 'package:flutter_kts_template/core/channels/tools/channel.abstract.dart';
import 'package:flutter_kts_template/core/channels/tools/channel.event.dart';

class ChannelManagerUdp implements ChannelAbstract {
  @override
  Future<void> connect(String rPeer) {
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  // TODO: implement eventStream
  Stream<ChannelEvent> get eventStream => throw UnimplementedError();

  @override
  Future<List<String>> getDevices() {
    throw UnimplementedError();
  }

  @override
  // TODO: implement receiveStream
  Stream<Uint8List> get receiveStream => throw UnimplementedError();

  @override
  Future<void> write(Uint8List data) {
    // TODO: implement write
    throw UnimplementedError();
  }
}
