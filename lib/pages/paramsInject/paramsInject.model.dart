import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class MasterConfig {
  String searchValue;
  bool visible;
  MasterSelectConfig select;
  TextEditingController searchTextFieldController;
  MasterConfig({
    required this.searchValue,
    required this.visible,
    required this.select,
    required this.searchTextFieldController,
  });
}

class MasterSelectConfig {
  String id;
  String type;
  MasterSelectConfig({required this.id, required this.type});
}

class RadioModel {
  List<Uint8List> packets; // 包
  final String address; // 电台地址
  Uint8List packetHeader; // 总共的字节
  int? userId;
  String? tarPath;

  RadioModel({
    required this.packets,
    required this.address,
    required this.packetHeader,
    this.userId,
    this.tarPath,
  });
}
