import 'dart:typed_data';

class RtcReceive {
  final String address;
  final Uint8List data;
  final int port;
  RtcReceive({required this.address, required this.data, required this.port});
}
