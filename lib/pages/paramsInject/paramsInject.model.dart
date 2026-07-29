import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart'
    show SimpleTreeNode;
import 'package:flutter_kts_template/core/rtc/managers/socketIO/socket.io.manager.dart';
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
  bool treeVisible;
  DetailTreeDialogConfig dialog;
  Map<String, TreeType<SimpleTreeNode>> selectRows;
  int activeStep;
  int selectWifi;
  SocketIOManager? socketIOManager;
  DetailTreeConfig({
    required this.data,
    required this.visible,
    required this.dialog,
    required this.selectRows,
    required this.activeStep,
    required this.selectWifi,
    required this.socketIOManager,
    required this.treeVisible,
  });
}

class DetailTreeDialogConfig {
  TextEditingController deviceType;
  TextEditingController deviceIP;
  DetailTreeDialogConfig({required this.deviceType, required this.deviceIP});
}

class DeviceFileModel {
  int? userId;
  String? tarPath;
  List<Uint8List> packets; // 包
  Uint8List packetHeader; // 总共的字节

  DeviceFileModel({
    this.userId,
    this.tarPath,
    required this.packets,
    required this.packetHeader,
  });
}
