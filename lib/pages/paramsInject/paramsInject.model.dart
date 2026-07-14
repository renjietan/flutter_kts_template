import 'dart:typed_data';

class RadioModel {
  List<Uint8List> packets; // 包
  final String address; // 电台地址
  Uint8List packetHeader; // 总共的字节

  RadioModel({
    required this.packets,
    required this.address,
    required this.packetHeader,
  });
}
