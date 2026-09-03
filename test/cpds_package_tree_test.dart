import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:flutter_kts_template/pages/cpds/cpds_package_tree.dart';
import 'package:flutter_test/flutter_test.dart';

CpdsNode _node(String id, {int nodeType = 0}) => CpdsNode(
  id: id,
  guid: 'guid-$id',
  name: id,
  networkSegment: '',
  nodeType: nodeType,
  model: '',
  devices: const [],
);

CpdsUnit _unit(
  String id, {
  List<String> nodeIds = const [],
  List<CpdsUnit> subUnits = const [],
}) => CpdsUnit(id: id, name: id, nodeIds: nodeIds, subUnits: subUnits);

Map<String, CpdsNode> _nodes(List<CpdsNode> list) => {
  for (final n in list) n.id: n,
};

void main() {
  group('buildCpdsPackageTree', () {
    test('nodeType==1 归入 CS，N 计数正确，普通节点在前', () {
      final tree = buildCpdsPackageTree(
        [_unit('u1', nodeIds: ['n1', 'n2', 'n3'])],
        _nodes([
          _node('n1', nodeType: 1),
          _node('n2', nodeType: 1),
          _node('n3', nodeType: 2),
        ]),
      );

      expect(tree, hasLength(1));
      final u = tree.first;
      expect(u.kind, CpdsTreeItemKind.unit);
      expect(u.children, hasLength(2));

      expect(u.children[0].kind, CpdsTreeItemKind.node);
      expect(u.children[0].nodeId, 'n3');

      final cs = u.children[1];
      expect(cs.kind, CpdsTreeItemKind.futureWarrior);
      expect(cs.title, '未来战士（2）');
      expect(cs.children, isEmpty);
      expect(cs.unitId, 'u1');
    });

    test('没有 nodeType==1 时不显示 CS', () {
      final tree = buildCpdsPackageTree(
        [_unit('u1', nodeIds: ['n1', 'n2'])],
        _nodes([_node('n1', nodeType: 2), _node('n2', nodeType: 0)]),
      );

      final u = tree.first;
      expect(
        u.children.where(
          (c) => c.kind == CpdsTreeItemKind.futureWarrior,
        ),
        isEmpty,
      );
    });

    test('CS 位于普通节点之后、subUnits 之前', () {
      final tree = buildCpdsPackageTree(
        [
          _unit(
            'u1',
            nodeIds: ['n1', 'n2'],
            subUnits: [_unit('u2', nodeIds: ['n3'])],
          ),
        ],
        _nodes([
          _node('n1', nodeType: 1),
          _node('n2', nodeType: 2),
          _node('n3', nodeType: 0),
        ]),
      );

      final u = tree.first;
      expect(u.children.map((c) => c.kind), [
        CpdsTreeItemKind.node, // n2
        CpdsTreeItemKind.futureWarrior, // CS
        CpdsTreeItemKind.unit, // u2
      ]);
    });

    test('不跨 subUnits 递归收集 nodeType==1', () {
      final tree = buildCpdsPackageTree(
        [
          _unit(
            'u1',
            nodeIds: ['n1'],
            subUnits: [_unit('u2', nodeIds: ['n2'])],
          ),
        ],
        _nodes([_node('n1', nodeType: 1), _node('n2', nodeType: 1)]),
      );

      final u1 = tree.first;
      final cs1 = u1.children.singleWhere(
        (c) => c.kind == CpdsTreeItemKind.futureWarrior,
      );
      expect(cs1.title, '未来战士（1）');
      expect(cs1.children, isEmpty);
      expect(cs1.unitId, 'u1');

      final u2 = u1.children.singleWhere(
        (c) => c.kind == CpdsTreeItemKind.unit,
      );
      final cs2 = u2.children.singleWhere(
        (c) => c.kind == CpdsTreeItemKind.futureWarrior,
      );
      expect(cs2.title, '未来战士（1）');
      expect(cs2.children, isEmpty);
      expect(cs2.unitId, 'u2');
    });

    test('空 unit 是叶子节点（无 children）', () {
      final tree = buildCpdsPackageTree([_unit('u1')], _nodes([]));
      expect(tree.first.isLeaf, isTrue);
      expect(tree.first.children, isEmpty);
    });
  });

  group('filterCpdsTree', () {
    late List<CpdsTreeItem> tree;

    setUp(() {
      tree = buildCpdsPackageTree(
        [
          _unit('u1', nodeIds: ['n1', 'n3'], subUnits: [
            _unit('u2', nodeIds: ['n4']),
          ]),
        ],
        _nodes([
          _node('n1', nodeType: 1),
          _node('n3', nodeType: 2),
          _node('n4', nodeType: 0),
        ]),
      );
    });

    test('空 query 返回完整树', () {
      expect(filterCpdsTree(tree, ''), hasLength(1));
    });

    test('命中普通节点时保留其祖先路径', () {
      final result = filterCpdsTree(tree, 'n3');
      final u1 = result.single;
      expect(u1.children.map((c) => c.nodeId), ['n3']);
      expect(
        u1.children.where(
          (c) => c.kind == CpdsTreeItemKind.futureWarrior,
        ),
        isEmpty,
      );
    });

    test('CS 标题不参与搜索', () {
      expect(filterCpdsTree(tree, '未来战士'), isEmpty);
    });

    test('nodeType==1 节点已归入 CS，不再单独匹配', () {
      expect(filterCpdsTree(tree, 'n1'), isEmpty);
    });

    test('unit 名称命中时保留该 unit（子节点按匹配过滤）', () {
      final result = filterCpdsTree(tree, 'u1');
      final u1 = result.single;
      expect(u1.title, 'u1');
      expect(u1.children, isEmpty);
    });
  });

  group('flattenCpdsTree', () {
    late List<CpdsTreeItem> tree;

    setUp(() {
      tree = buildCpdsPackageTree(
        [
          _unit('u1', nodeIds: ['n1'], subUnits: [
            _unit('u2', nodeIds: ['n2']),
          ]),
        ],
        _nodes([_node('n1'), _node('n2')]),
      );
    });

    test('默认收起只显示顶层 unit', () {
      final rows = flattenCpdsTree(tree, {});
      expect(rows.map((r) => r.item.key), ['unit:u1']);
      expect(rows.single.expanded, isFalse);
    });

    test('展开父节点后显示其直接子节点', () {
      final rows = flattenCpdsTree(tree, {'unit:u1'});
      expect(
        rows.map((r) => r.item.key),
        ['unit:u1', 'node:n1', 'unit:u2'],
      );
    });

    test('逐级展开显示全部节点', () {
      final rows = flattenCpdsTree(tree, {'unit:u1', 'unit:u2'});
      expect(
        rows.map((r) => r.item.key),
        ['unit:u1', 'node:n1', 'unit:u2', 'node:n2'],
      );
    });

    test('forceExpandAll 强制展开所有非叶子节点', () {
      final rows = flattenCpdsTree(tree, {}, forceExpandAll: true);
      expect(
        rows.map((r) => r.item.key),
        ['unit:u1', 'node:n1', 'unit:u2', 'node:n2'],
      );
    });
  });
}
