import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';

/// CPDS 树节点的类型。
enum CpdsTreeItemKind {
  /// 普通 unit（指挥层级）。
  unit,

  /// 普通节点（nodeType != 1）。
  node,

  /// 「未来战士」分组容器（包裹 nodeType == 1 节点）。
  futureWarrior,
}

/// CPDS 树中的一个节点（纯数据模型，便于单元测试）。
class CpdsTreeItem {
  const CpdsTreeItem({
    required this.kind,
    required this.key,
    required this.title,
    required this.depth,
    this.nodeId,
    this.nodeType,
    this.unitId,
    this.children = const [],
  });

  final CpdsTreeItemKind kind;

  /// 展开/收起状态使用的唯一 key。
  final String key;

  final String title;
  final int depth;

  /// 仅 node 类型有值，用于选中节点并传给右侧面板。
  final String? nodeId;

  /// 仅 node 类型有值，用于图标。
  final int? nodeType;

  /// 仅 futureWarrior 类型有值，用于选中「未来战士」分组。
  final String? unitId;

  final List<CpdsTreeItem> children;

  bool get isLeaf => children.isEmpty;

  CpdsTreeItem copyWith({List<CpdsTreeItem>? children}) {
    return CpdsTreeItem(
      kind: kind,
      key: key,
      title: title,
      depth: depth,
      nodeId: nodeId,
      nodeType: nodeType,
      unitId: unitId,
      children: children ?? this.children,
    );
  }
}

/// 展平后的一行可见数据，附带当前是否展开（用于渲染箭头方向）。
class CpdsVisibleRow {
  const CpdsVisibleRow({required this.item, required this.expanded});

  final CpdsTreeItem item;
  final bool expanded;
}

/// 构建 CPDS 树：
/// - 普通节点（nodeType != 1）直接挂在 unit 下；
/// - nodeType == 1 的节点归入「未来战士（N）」分组，位置在普通节点之后、
///   subUnits 之前；
/// - 不跨 subUnits 递归收集。
List<CpdsTreeItem> buildCpdsPackageTree(
  List<CpdsUnit> units,
  Map<String, CpdsNode> nodesById, {
  String futureWarriorLabel = '未来战士',
}) {
  return units
      .map(
        (unit) => _buildUnit(unit, nodesById, 0, futureWarriorLabel),
      )
      .toList();
}

CpdsTreeItem _buildUnit(
  CpdsUnit unit,
  Map<String, CpdsNode> nodesById,
  int depth,
  String futureWarriorLabel,
) {
  final children = <CpdsTreeItem>[];
  var futureWarriorCount = 0;

  for (final nodeId in unit.nodeIds) {
    final node = nodesById[nodeId];
    if (node == null) continue;
    if (node.nodeType == 1) {
      futureWarriorCount++;
      continue; // nodeType==1 节点不再单独展示，统一归入 CS。
    }
    children.add(
      CpdsTreeItem(
        kind: CpdsTreeItemKind.node,
        key: 'node:${node.id}',
        title: node.name,
        depth: depth + 1,
        nodeId: node.id,
        nodeType: node.nodeType,
      ),
    );
  }

  if (futureWarriorCount > 0) {
    children.add(
      CpdsTreeItem(
        kind: CpdsTreeItemKind.futureWarrior,
        key: 'cs:${unit.id}',
        title: '$futureWarriorLabel（$futureWarriorCount）',
        depth: depth + 1,
        unitId: unit.id,
      ),
    );
  }

  for (final sub in unit.subUnits) {
    children.add(_buildUnit(sub, nodesById, depth + 1, futureWarriorLabel));
  }

  return CpdsTreeItem(
    kind: CpdsTreeItemKind.unit,
    key: 'unit:${unit.id}',
    title: unit.name,
    depth: depth,
    children: children,
  );
}

/// 按 query 过滤树：保留「匹配节点 + 其祖先路径」，其余隐藏。
///
/// 说明：futureWarrior 分组标题不参与搜索，只有它下面的 nodeType==1 子节点
/// 命中时，它才作为祖先保留。
List<CpdsTreeItem> filterCpdsTree(List<CpdsTreeItem> items, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return items;
  return items
      .map((item) => _filterItem(item, normalized))
      .whereType<CpdsTreeItem>()
      .toList();
}

CpdsTreeItem? _filterItem(CpdsTreeItem item, String query) {
  final nameMatches =
      item.kind != CpdsTreeItemKind.futureWarrior &&
      item.title.toLowerCase().contains(query);

  if (item.isLeaf) {
    return nameMatches ? item : null;
  }

  final filteredChildren = item.children
      .map((child) => _filterItem(child, query))
      .whereType<CpdsTreeItem>()
      .toList();

  if (nameMatches || filteredChildren.isNotEmpty) {
    return item.copyWith(children: filteredChildren);
  }
  return null;
}

/// 将树展平为可见行列表。
///
/// [forceExpandAll] 为 true 时（搜索中），所有非叶子节点都视为展开，保证命中
/// 节点及其祖先路径可见。
List<CpdsVisibleRow> flattenCpdsTree(
  List<CpdsTreeItem> items,
  Set<String> expandedKeys, {
  bool forceExpandAll = false,
}) {
  final result = <CpdsVisibleRow>[];
  for (final item in items) {
    final expanded =
        item.children.isNotEmpty &&
        (forceExpandAll || expandedKeys.contains(item.key));
    result.add(CpdsVisibleRow(item: item, expanded: expanded));
    if (expanded) {
      result.addAll(
        flattenCpdsTree(
          item.children,
          expandedKeys,
          forceExpandAll: forceExpandAll,
        ),
      );
    }
  }
  return result;
}
