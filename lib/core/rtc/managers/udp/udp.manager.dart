import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/rtc/managers/udp/udp.address.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.abstract.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.event.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:udp/udp.dart';

import '../../tools/rtc.event.type.dart';

class UdpManager implements RtcAbstract {
  static final UdpManager _instance = UdpManager._internal();

  factory UdpManager() => _instance;

  UdpManager._internal();

  late UDP _udp;
  bool _initialized = false;
  final Map<String, Endpoint> _remoteEndpoints = {};
  final StreamController<RtcReceive> _onDataStreamController =
      StreamController<RtcReceive>.broadcast();
  final StreamController<RtcEvent> _onEventController =
      StreamController<RtcEvent>.broadcast();

  @override
  Future<void> init(String localPeerAddress) async {
    try {
      UdpAddress udpAddress = UdpAddress.fromString(localPeerAddress);
      Endpoint endpoint = Endpoint.any(port: Port(udpAddress.port));
      _udp = await UDP.bind(endpoint);
      _initialized = true;
      // 服务建立失败
      if (_udp.closed) {
        _onEventController.sink.add(RtcEvent(type: RtcEventType.closed));
        return;
      }
      _udp.asStream().listen((Datagram? data) {
        if (data?.data != null) {
          _onDataStreamController.sink.add(
            RtcReceive(
              address: data!.address.address,
              data: data.data.buffer.asUint8List(),
              port: data.port,
            ),
          );
        } else {
          _onEventController.sink.add(
            RtcEvent(type: RtcEventType.error, msg: t.common.noData),
          );
        }
      });
      _onEventController.sink.add(RtcEvent(type: RtcEventType.created));
    } catch (e) {
      GlobalLogger.logError(e.toString());
    }
  }

  @override
  Future<void> connect(String remotePeerAddress) async {}

  @override
  Future<void> disconnect() async {
    if (!_initialized) return;
    _udp.close();
    _initialized = false;
    _remoteEndpoints.clear();
  }

  @override
  Future<void> write(Uint8List data, String remotePeerAddress) async {
    UdpAddress address = UdpAddress.fromString(remotePeerAddress);
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
  Stream<RtcReceive> get receiveStream => _onDataStreamController.stream;
}
