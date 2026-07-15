import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart'
    show SimpleTreeNode;
import 'package:recursive_tree_flutter/models/tree_type.dart';

class MasterTreeConfig {
  String searchValue;
  bool visible;
  MasterTreeSelectConfig select;
  TextEditingController searchTextFieldController;
  TreeType<SimpleTreeNode> data;
  MasterTreeConfig({
    required this.searchValue,
    required this.visible,
    required this.select,
    required this.searchTextFieldController,
    required this.data,
  });
}

class MasterTreeSelectConfig {
  String id;
  int type;
  String title;
  MasterTreeSelectConfig({
    required this.id,
    required this.type,
    required this.title,
  });
}

class DetailTreeConfig {
  List<TreeType<SimpleTreeNode>> data;
  bool visible;

  DetailTreeConfig({required this.data, required this.visible});
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
