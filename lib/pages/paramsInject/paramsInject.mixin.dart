import 'package:flutter/cupertino.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/TreeView/simple-tree/simple.tree.model.dart';

mixin ParamsInjectMixin<T extends StatefulWidget> on State<T> {
  List<Uri> paths = [];

  Future<List<Uri>> getTreeData() async {
    await Future.delayed(Duration(seconds: 3));
    paths = [
      Uri.parse('file:///documents/1'),
      Uri.parse('file:///documents/images/2'),
    ];
    return paths;
  }

  void parseTree(
    Map<String, dynamic> node, [
    int depth = 0,
    TreeType<SimpleTreeNode>? res,
  ]) {
    if (node['children'] != null && node['children'].isNotEmpty) {
      for (var child in node['children']) {
        parseTree(child, depth + 1);
      }
    }
  }

  TreeType<SimpleTreeNode> sampleVNRegionNode<T extends AbsNodeType>() {
    return TreeType<SimpleTreeNode>(
      data: SimpleTreeNode(id: 0, title: "Việt Nam", level: 0, index: 0),
      children: [],
      parent: null,
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
}
