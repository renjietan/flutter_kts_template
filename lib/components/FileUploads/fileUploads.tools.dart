import '../../i18n/handle/translations.g.dart';

Map<String, dynamic> transformUnitTree(
  Map<String, dynamic> node, {
  required bool fillNode,
  bool enableFutureWarriorGroup = false,
}) {
  // 1. 虚拟分组节点特殊处理
  if (node['isFutureWarriorGroup'] == true) {
    final unit = node['Unit'] as Map<String, dynamic>;
    final result = <String, dynamic>{
      'id': unit['UnitId'],
      'title': unit['CodeName'],
      'isleaf': false,
      'type': unit['NodeType'] ?? 4, // 使用实际类型（应为4）
      'users': [],
    };
    final subUnits = (node['SubUnits'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    result['children'] = subUnits
        .map(
          (child) => transformUnitTree(
            child,
            fillNode: fillNode,
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

  var subUnits = (node['SubUnits'] as List? ?? []).cast<Map<String, dynamic>>();
  final netNodes = (node['NetNodes'] as List? ?? [])
      .cast<Map<String, dynamic>>();

  // 2. 处理 NetNodes
  if (!isLeaf && netNodes.isNotEmpty) {
    final allConverted = netNodes.map((n) => transformNetNode(n)).toList();

    if (enableFutureWarriorGroup) {
      // 启用分组：NodeType==4 的节点放入虚拟父节点
      final normalNodes = allConverted
          .where((item) => item['NodeType'] != 4)
          .toList();
      final futureWarriorNodes = allConverted
          .where((item) => item['NodeType'] == 4)
          .toList();

      // 不再修改未来战士节点的 NodeType，保留其原始类型 4

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
            'NodeType': -1, // 占位节点无特殊类型
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

  // 3. fillNode 逻辑
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
