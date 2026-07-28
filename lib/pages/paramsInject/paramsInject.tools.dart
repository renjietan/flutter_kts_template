import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/FileUploads/fileUploads.mixin.dart';
import '../../core/utils/director.dart';
import '../../i18n/handle/translations.g.dart';
import '../../utils/files/FileTools.dart';

// leafActionWidgetLabel 叶子节点 右侧 按钮文字
// leafActionWidgetOnPressed 叶子节点 右侧 点击事件
// leafActionWidgetSize 叶子节点 右侧组件宽度
// activeSelection 是否启用 勾选框
// 下标从 几 开始，主要用于多颗树的斑马线
// 返回 树状列表 AND 节点总数量，用于将节点数量 传入到 下一颗树中，让多棵树的斑马线显得比较连贯
(TreeType<SimpleTreeNode>, int) buildTree(
  Map<String, dynamic> rootData, {
  String? leafActionWidgetLabel,
  void Function(SimpleTreeNode)? leafActionWidgetOnPressed,
  Size? leafActionWidgetSize,
  bool? activeSelection,
  int? startIndex,
}) {
  (TreeType<SimpleTreeNode>, int) buildNodes(
    Map<String, dynamic> data,
    TreeType<SimpleTreeNode>? parent,
    int level,
    int currentIndex,
  ) {
    int nextIndex = data["title"] == t.tree.empty
        ? currentIndex
        : currentIndex + 1;
    double padding =
        level * 16 +
        (data["type"] == 4 && data["children"].length != 0 ? 24 : 0);
    Color nodeBgColor = currentIndex % 2 == 0
        ? Color(0xFF171C22)
        : Color(0xFF23282D);
    // print("data" + data.toString());
    var node = TreeType<SimpleTreeNode>(
      data: SimpleTreeNode(
        id: data["id"],
        title: data["title"],
        level: level,
        index: currentIndex,
        nodeBgColor: nodeBgColor,
        padding: padding,
        type: data["type"],
        subTexts: data["subTexts"] ?? [],
      ),
      children: [],
      parent: parent,
    );
    final rawChildren = (data['children'] ?? []) as List<dynamic>;
    List<TreeType<SimpleTreeNode>> childNodes = [];
    for (var childData in rawChildren) {
      if (childData is Map<String, dynamic>) {
        var (childNode, newIndex) = buildNodes(
          childData,
          node,
          level + 1,
          nextIndex,
        );
        childNodes.add(childNode);
        nextIndex = newIndex;
      }
    }
    node.children = childNodes;
    if (node.children.isEmpty) {
      node.data.isInner = !data["isleaf"];
      node.data.padding = node.data.padding + 10;
      node.data.titleIcon = getTreeNodeIcon(data["type"]);
      node.data.isShowCheckbox = data["isShowCheckbox"] ?? false;
      node.data.isChosen = data["isChosen"] ?? false;
      if (leafActionWidgetLabel != null) {
        node.data.leafActionWidgetLabel = leafActionWidgetLabel;
      }
      if (leafActionWidgetOnPressed != null) {
        node.data.leafActionWidgetOnPressed = leafActionWidgetOnPressed;
      }
      if (leafActionWidgetSize != null) {
        node.data.leafActionWidgetSize = leafActionWidgetSize;
      }
      if (activeSelection != null) {
        node.data.activeSelection = activeSelection;
      }
    }
    return (node, nextIndex);
  }

  // 从根节点开始，层级为1，索引从0开始
  var (rootNode, nIndex) = buildNodes(rootData, null, 0, startIndex ?? 0);
  return (rootNode, nIndex);
}

IconData getTreeNodeIcon(int type) {
  IconData res;
  switch (type) {
    case 1: // 未来战士
      res = HyIcons.ren;
      break;
    case 2: // 车
      res = HyIcons.che;
      break;
    case 3: // 指挥所
      res = HyIcons.zhihuisuo;
      break;
    default:
      res = HyIcons.wenjian;
  }
  return res;
}

/// [directoryPath] 获取文件夹下 所有文本内容
///
/// 返回 Map，键为文件名，值为解析后的 JSON 对象（Map 或 List）。
Future<(Map<String, dynamic>, String)> readAllDataFiles(
  String? filePath,
) async {
  if (filePath != null && filePath.isNotEmpty) {
    var res = await parseData(filePath);
    return (res, filePath);
  }
  String defaultUploadPath = await DirectoryManager.instance.getUploadsPath();
  List<Directory> subFolders = await FileTools.getDirectSubFolders(
    defaultUploadPath,
  );
  if (subFolders.isEmpty) return (<String, dynamic>{}, "");
  subFolders.sort((a, b) {
    DateTime timeA = a.statSync().changed;
    DateTime timeB = b.statSync().changed;
    return timeB.compareTo(timeA);
  });
  var res = await parseData(subFolders[0].path);
  return (res, subFolders[0].path);
}

/// 递归将 unit 中的 NetNodes 转为 SubUnits 里的子单元
Map<String, dynamic> transformUnitTree(
  Map<String, dynamic> unit, {
  bool isShowCheckbox = false,
  bool isRoot = true, // 这个参数不用传，函数内部作为标记使用
  required Map<String, dynamic> fullData,
}) {
  if (isRoot) {
    String unitId = unit["UnitId"] ?? "";
    String unitName = fullData["6_unit"]?[unitId]?["UnitName"] ?? "未找到";
    unit = {
      "id": unitId,
      "title": unitName,
      "NetNodes": unit["NetNodes"],
      "UserIds": unit["UserIds"],
      "children": unit["SubUnits"],
      "isleaf": false,
      "isShowCheckbox": isShowCheckbox,
      "type": 999,
    };
  }
  List<dynamic> netNodes = List<dynamic>.from(unit['NetNodes'] ?? []);
  List<dynamic> subUnits = List<dynamic>.from(unit['children'] ?? []);

  List<Map<String, dynamic>> nSubUnits = subUnits.map((sub) {
    String unitId = sub["UnitId"] ?? "";
    String unitName = fullData["6_unit"]?[unitId]?["UnitName"] ?? "未找到";
    Map<String, dynamic> nSub = {
      "id": unitId,
      "title": unitName,
      "NetNodes": sub["NetNodes"],
      "UserIds": sub["UserIds"],
      "children": sub["SubUnits"],
      "isleaf": false,
      "isShowCheckbox": isShowCheckbox,
      "type": sub["type"] ?? 999,
    };
    return transformUnitTree(
      Map<String, dynamic>.from(nSub),
      fullData: fullData,
      isShowCheckbox: isShowCheckbox,
      isRoot: false,
    );
  }).toList();
  int randomId = DateTime.now().millisecondsSinceEpoch;
  List<Map<String, dynamic>> nNetNodes = netNodes.fold(
    [
      <String, dynamic>{
        'id': "nfs_$randomId",
        "title": t.pager.injectParams.futureSoldier,
        'UserIds': <Map<String, dynamic>>[],
        'children': <Map<String, dynamic>>[],
        "isleaf": false,
        "isShowCheckbox": isShowCheckbox,
        "type": 999,
      },
    ],
    (cur, pre) {
      Map<String, dynamic> nn_fileInfo = fullData["4_net_node"]?[pre] ?? {};
      Map<String, dynamic> nn_baseInfo = nn_fileInfo["BasicInfo"] ?? {};
      var items = <String, dynamic>{
        'id': pre,
        "title": nn_baseInfo["NodeName"] ?? t.common.noData,
        'UserIds': <String>[],
        'children': <Map>[],
        "isleaf": true,
        "isShowCheckbox": isShowCheckbox,
        "type": nn_baseInfo["NodeType"] ?? -1,
      };
      if (pre.startsWith("nn_futureSoldier")) {
        print(cur[cur.length - 1]["children"]);
        cur[cur.length - 1]["children"].add(items);
      } else {
        cur = [items, ...cur];
      }
      return cur;
    },
  ).toList();
  if (nNetNodes[nNetNodes.length - 1]["children"].length == 0) {
    nNetNodes.removeLast();
  }
  unit['children'] = [...nNetNodes, ...nSubUnits];
  return unit;
}
