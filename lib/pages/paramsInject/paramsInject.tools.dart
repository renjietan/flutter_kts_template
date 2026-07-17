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
    var node = TreeType<SimpleTreeNode>(
      data: SimpleTreeNode(
        id: data["id"],
        title: data["title"],
        level: level,
        index: currentIndex,
        nodeBgColor: nodeBgColor,
        padding: padding,
        type: data["type"],
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
    case 1: // 指挥所
      res = HyIcons.zhihuisuo;
      break;
    case 2: // 车
      res = HyIcons.che;
      break;
    case 4: // 未来战士
      res = HyIcons.ren;
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
        "title": "未来战士",
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
        "title": nn_baseInfo["NodeName"] ?? "未找到",
        'UserIds': <String>[],
        'children': <Map>[],
        "isleaf": true,
        "isShowCheckbox": isShowCheckbox,
        "type": nn_baseInfo["NodeType"] ?? -1,
      };
      if (pre.startsWith("nn_futureSoldier")) {
        cur[cur.length - 1]["children"].add(items);
      } else {
        cur = [items, ...cur];
      }
      return cur;
    },
  ).toList();
  if (nNetNodes[netNodes.length - 1]["children"].length == 0) {
    nNetNodes.removeLast();
  }
  unit['children'] = [...nNetNodes, ...nSubUnits];
  return unit;
}

// Map<String, dynamic> transformUnitTree(
//   Map<String, dynamic> node, {
//   required Map<String, dynamic> fullData,
//   required bool fillNode,
//   bool enableFutureWarriorGroup = false,
//   bool isShowCheckbox = false,
// }) {
//   final unitId = node["UnitId"];
//   final unitMap = fullData["6_unit"][unitId] ?? {};
//   final unitName = unitMap["name"] ?? unitId;
//   // 虚拟分组节点特殊处理
//   if (node['isFutureWarriorGroup'] == true) {
//     final result = <String, dynamic>{
//       'id': unitId,
//       'title': unitName,
//       'isleaf': false,
//       'type': unitId ?? 999,
//       'users': [],
//     };
//     final subUnits = (node['SubUnits'] as List? ?? [])
//         .cast<Map<String, dynamic>>();
//     result['children'] = subUnits
//         .map(
//           (child) => transformUnitTree(
//             child,
//             fillNode: fillNode,
//             isShowCheckbox: isShowCheckbox,
//             enableFutureWarriorGroup: enableFutureWarriorGroup,
//             fullData: fullData,
//           ),
//         )
//         .toList();
//     return result;
//   }
//
//   var unit = node['Unit'] as Map<String, dynamic>;
//   final isLeaf = (unit['isleaf'] as bool?) ?? false;
//
//   final result = <String, dynamic>{
//     'id': unit['UnitId'],
//     'title': unit['CodeName'],
//     'isleaf': isLeaf,
//     'type': unit['NodeType'] ?? 999,
//     'users': unit['Users'] ?? [],
//   };
//
//   if (isLeaf) {
//     result['isShowCheckbox'] = isShowCheckbox;
//   }
//
//   var subUnits = (node['SubUnits'] as List? ?? []).cast<Map<String, dynamic>>();
//   final netNodes = (node['NetNodes'] as List? ?? [])
//       .cast<Map<String, dynamic>>();
//
//   // 处理 NetNodes
//   if (!isLeaf && netNodes.isNotEmpty) {
//     final allConverted = netNodes.map((n) => transformNetNode(n)).toList();
//
//     if (enableFutureWarriorGroup) {
//       final normalNodes = allConverted
//           .where((item) => item['NodeType'] != 4)
//           .toList();
//       final futureWarriorNodes = allConverted
//           .where((item) => item['NodeType'] == 4)
//           .toList();
//
//       final List<Map<String, dynamic>> groupChildren = [];
//       if (futureWarriorNodes.isNotEmpty) {
//         groupChildren.addAll(futureWarriorNodes);
//       } else {
//         // 无未来战士时填入占位叶子
//         groupChildren.add({
//           'Unit': {
//             'UnitId': DateTime.now().millisecondsSinceEpoch + 999,
//             'CodeName': t.tree.empty,
//             'isleaf': true,
//             'NodeType': -1,
//           },
//           'NetNodes': [],
//           'SubUnits': [],
//         });
//       }
//
//       final futureWarriorsGroup = <String, dynamic>{
//         'isFutureWarriorGroup': true,
//         'Unit': {
//           'UnitId': DateTime.now().millisecondsSinceEpoch,
//           'CodeName': t.tree.futureWarrior,
//           'isleaf': false,
//           'NodeType': 4, // 父节点类型设为4
//         },
//         'NetNodes': [],
//         'SubUnits': groupChildren,
//       };
//
//       subUnits = [...normalNodes, futureWarriorsGroup, ...subUnits];
//     } else {
//       // 不启用分组：所有节点直接作为子节点
//       subUnits = [...allConverted, ...subUnits];
//     }
//   }
//
//   // 是否需要填充节点
//   if (!isLeaf && subUnits.isEmpty && fillNode) {
//     int randomNum = DateTime.now().millisecondsSinceEpoch;
//     subUnits = [
//       {
//         "Unit": {
//           "UnitId": randomNum + 1,
//           "CodeName": t.tree.empty,
//           "isleaf": true,
//         },
//       },
//     ];
//   }
//
//   result['children'] = subUnits
//       .map(
//         (child) => transformUnitTree(
//           child,
//           fillNode: fillNode,
//           fullData: fullData,
//           isShowCheckbox: isShowCheckbox,
//           enableFutureWarriorGroup: enableFutureWarriorGroup,
//         ),
//       )
//       .toList();
//   return result;
// }
//
// Map<String, dynamic> transformNetNode(Map<String, dynamic> netNode) {
//   return {
//     'NodeType': netNode['NodeType'], // 保留原始类型（如4）
//     'Unit': {
//       'UnitId': netNode['NodeId'],
//       'CodeName': netNode['CodeName'],
//       'isleaf': true,
//       'NodeType': netNode['NodeType'], // 保留原始类型
//       'Users': netNode['Users'] ?? [],
//     },
//     'NetNodes': [],
//     'SubUnits': [],
//   };
// }
