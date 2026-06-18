import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.treeview.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

class ExVNRegionsTree extends StatefulWidget {
  const ExVNRegionsTree({super.key});

  @override
  State<ExVNRegionsTree> createState() => _ExVNRegionsTreeState();
}

class _ExVNRegionsTreeState extends State<ExVNRegionsTree> {
  late TreeType<SimpleTreeNode> _tree;

  TreeType<SimpleTreeNode> sampleVNRegionNode<T extends AbsNodeType>() {
    return TreeType<SimpleTreeNode>(
      data: SimpleTreeNode(id: 0, title: "Việt Nam", level: 0, index: 0),
      children: [],
      parent: null,
    );
  }

  @override
  void initState() {
    setState(() {
      _tree = sampleVNRegionNode();
    });
    super.initState();
    Future.delayed(Duration(seconds: 10)).then((_) {
      setState(() {
        _tree = TreeType<SimpleTreeNode>(
          data: SimpleTreeNode(id: 0, title: "Việt Nam", level: 0, index: 0),
          children: [],
          parent: null,
        );
      });
      Future.delayed(Duration(seconds: 10)).then((_) {
        setState(() {
          _tree = sampleVNRegionNode();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SimpleTreeView(_tree, onNodeDataChanged: () => setState(() {})),
    );
  }
}
