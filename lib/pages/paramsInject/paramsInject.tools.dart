import 'dart:io';

import '../../components/FileUploads/fileUploads.mixin.dart';
import '../../core/utils/director.dart';
import '../../i18n/handle/translations.g.dart';
import '../../utils/files/FileTools.dart';

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

Map<String, dynamic> transformUnitTree(
  Map<String, dynamic> node, {
  required bool fillNode,
  bool enableFutureWarriorGroup = false,
  bool isShowCheckbox = false,
}) {
  // 虚拟分组节点特殊处理
  if (node['isFutureWarriorGroup'] == true) {
    final unit = node['Unit'] as Map<String, dynamic>;
    final result = <String, dynamic>{
      'id': unit['UnitId'],
      'title': unit['CodeName'],
      'isleaf': false,
      'type': unit['NodeType'] ?? 4,
      'users': [],
    };
    final subUnits = (node['SubUnits'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    result['children'] = subUnits
        .map(
          (child) => transformUnitTree(
            child,
            fillNode: fillNode,
            isShowCheckbox: isShowCheckbox,
            enableFutureWarriorGroup: enableFutureWarriorGroup,
          ),
        )
        .toList();
    return result;
  }

  var unit = node['Unit'] as Map<String, dynamic>;
  final isLeaf = (unit['isleaf'] as bool?) ?? false;

  final result = <String, dynamic>{
    'id': unit['UnitId'],
    'title': unit['CodeName'],
    'isleaf': isLeaf,
    'type': unit['NodeType'] ?? -1,
    'users': unit['Users'] ?? [],
  };

  if (isLeaf) {
    result['isShowCheckbox'] = isShowCheckbox;
  }

  var subUnits = (node['SubUnits'] as List? ?? []).cast<Map<String, dynamic>>();
  final netNodes = (node['NetNodes'] as List? ?? [])
      .cast<Map<String, dynamic>>();

  // 处理 NetNodes
  if (!isLeaf && netNodes.isNotEmpty) {
    final allConverted = netNodes.map((n) => transformNetNode(n)).toList();

    if (enableFutureWarriorGroup) {
      final normalNodes = allConverted
          .where((item) => item['NodeType'] != 4)
          .toList();
      final futureWarriorNodes = allConverted
          .where((item) => item['NodeType'] == 4)
          .toList();

      final List<Map<String, dynamic>> groupChildren = [];
      if (futureWarriorNodes.isNotEmpty) {
        groupChildren.addAll(futureWarriorNodes);
      } else {
        // 无未来战士时填入占位叶子
        groupChildren.add({
          'Unit': {
            'UnitId': DateTime.now().millisecondsSinceEpoch + 999,
            'CodeName': t.tree.empty,
            'isleaf': true,
            'NodeType': -1,
          },
          'NetNodes': [],
          'SubUnits': [],
        });
      }

      final futureWarriorsGroup = <String, dynamic>{
        'isFutureWarriorGroup': true,
        'Unit': {
          'UnitId': DateTime.now().millisecondsSinceEpoch,
          'CodeName': t.tree.futureWarrior,
          'isleaf': false,
          'NodeType': 4, // 父节点类型设为4
        },
        'NetNodes': [],
        'SubUnits': groupChildren,
      };

      subUnits = [...normalNodes, futureWarriorsGroup, ...subUnits];
    } else {
      // 不启用分组：所有节点直接作为子节点
      subUnits = [...allConverted, ...subUnits];
    }
  }

  // 是否需要填充节点
  if (!isLeaf && subUnits.isEmpty && fillNode) {
    int randomNum = DateTime.now().millisecondsSinceEpoch;
    subUnits = [
      {
        "Unit": {
          "UnitId": randomNum + 1,
          "CodeName": t.tree.empty,
          "isleaf": true,
        },
      },
    ];
  }

  result['children'] = subUnits
      .map(
        (child) => transformUnitTree(
          child,
          fillNode: fillNode,
          isShowCheckbox: isShowCheckbox,
          enableFutureWarriorGroup: enableFutureWarriorGroup,
        ),
      )
      .toList();
  return result;
}

Map<String, dynamic> transformNetNode(Map<String, dynamic> netNode) {
  return {
    'NodeType': netNode['NodeType'], // 保留原始类型（如4）
    'Unit': {
      'UnitId': netNode['NodeId'],
      'CodeName': netNode['CodeName'],
      'isleaf': true,
      'NodeType': netNode['NodeType'], // 保留原始类型
      'Users': netNode['Users'] ?? [],
    },
    'NetNodes': [],
    'SubUnits': [],
  };
}
