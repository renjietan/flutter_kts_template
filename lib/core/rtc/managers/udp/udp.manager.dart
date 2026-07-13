import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/udp/udp.address.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:udp/udp.dart';

import '../../tools/rtc.event.type.dart';

class UdpManager implements RtcAbstract {
  static final UdpManager _instance = UdpManager._internal();

  factory UdpManager() => _instance;

  UdpManager._internal();

  late UDP _udp;
  final Map<String, Endpoint> _remoteEndpoints = {};
  final StreamController<Uint8List> _onDataStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<RtcEvent> _onEventController =
      StreamController<RtcEvent>.broadcast();

  @override
  Future<void> connect(String peerAddress) async {
    try {
      UdpAddress udpAddress = UdpAddress.fromString(peerAddress);
      Endpoint endpoint = Endpoint.any(port: Port(udpAddress.port));
      _udp = await UDP.bind(endpoint);
      // 服务建立失败
      if (_udp.closed) {
        _onEventController.sink.add(RtcEvent(type: RtcEventType.closed));
        return;
      }
      _udp.asStream().listen((Datagram? data) {
        print("数据接收 start==========================");
        print(data);
        print("数据接收 end==========================");
      });
      _onEventController.sink.add(RtcEvent(type: RtcEventType.closed));
    } catch (e) {
      GlobalLogger.logError(e.toString());
    }
  }

  @override
  Future<void> disconnect() async {
    _udp.close();
    _remoteEndpoints.clear();
  }

  @override
  Future<void> write(Uint8List data, String rPeer) async {
    UdpAddress address = UdpAddress.fromString(rPeer);
    // 远端地址
    Endpoint remoteEndpoint = Endpoint.multicast(
      address.address,
      port: Port(address.port),
    );
    String addressString = address.toString();
    _remoteEndpoints[addressString] = remoteEndpoint;
    // 返回发送的字节数
    int sentBytesLen = await _udp.send(data, remoteEndpoint);
    // -1: udp 已关闭，导致发送失败
    if (sentBytesLen == -1) {
      _remoteEndpoints.clear();
      _onEventController.sink.add(RtcEvent(type: RtcEventType.closed));
    }
  }

  @override
  Future<List<String>> getRemotePeers() async {
    return _remoteEndpoints.keys.toList();
  }

  @override
  // TODO: implement eventStream
  Stream<RtcEvent> get eventStream => _onEventController.stream;

  @override
  // TODO: implement receiveStream
  Stream<Uint8List> get receiveStream => _onDataStreamController.stream;
}
