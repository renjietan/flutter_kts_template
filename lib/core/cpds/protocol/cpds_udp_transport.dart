import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'cpd_protocol.dart';

class CpdsUdpTransport {
  CpdsUdpTransport();

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _loopbackSocket;
  RawDatagramSocket? _receiveSocket;
  final StreamController<CpdPacket> _packetController =
      StreamController<CpdPacket>.broadcast();

  Stream<CpdPacket> get packets => _packetController.stream;

  Future<void> init({required String? interfaceIp}) async {
    await close();
    final bindAddress = interfaceIp == null || interfaceIp.isEmpty
        ? InternetAddress.anyIPv4
        : InternetAddress(interfaceIp);

    _broadcastSocket = await RawDatagramSocket.bind(bindAddress, 0);
    _broadcastSocket!.broadcastEnabled = true;

    _loopbackSocket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    _loopbackSocket!.broadcastEnabled = true;

    _receiveSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      CpdProtocol.cpdsReceivePort,
    );
    _receiveSocket!.listen(_onReceive);
  }

  Future<void> send(CpdPacket packet) async {
    final datagram = CpdProtocol.encodePacket(packet);
    final broadcast = InternetAddress('255.255.255.255');
    final loopback = InternetAddress.loopbackIPv4;
    final broadcastSent = _sendTo(
      _broadcastSocket,
      datagram,
      broadcast,
      CpdProtocol.cpdcReceivePort,
    );
    final loopbackSent = _sendTo(
      _loopbackSocket,
      datagram,
      loopback,
      CpdProtocol.cpdcReceivePort,
    );
    if (broadcastSent == -1 && loopbackSent == -1) {
      throw const SocketException('all CPDS UDP send sockets failed');
    }
  }

  int _sendTo(
    RawDatagramSocket? socket,
    Uint8List data,
    InternetAddress address,
    int port,
  ) {
    if (socket == null) return -1;
    try {
      return socket.send(data, address, port);
    } catch (_) {
      return -1;
    }
  }

  void _onReceive(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final socket = _receiveSocket;
    if (socket == null) return;
    Datagram? datagram;
    while ((datagram = socket.receive()) != null) {
      final packet = CpdProtocol.decodePacket(datagram!.data);
      if (packet != null && !_packetController.isClosed) {
        _packetController.add(packet);
      }
    }
  }

  Future<void> close() async {
    _broadcastSocket?.close();
    _loopbackSocket?.close();
    _receiveSocket?.close();
    _broadcastSocket = null;
    _loopbackSocket = null;
    _receiveSocket = null;
  }

  Future<void> dispose() async {
    await close();
    await _packetController.close();
  }
}
