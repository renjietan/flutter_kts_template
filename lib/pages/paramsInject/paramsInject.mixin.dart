import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/TreeView/simple-tree/simple.tree.model.dart';

mixin ParamsInjectMixin<T extends StatefulWidget> on State<T> {
  List<Uri> paths = [];

  TreeType<SimpleTreeNode> buildTree(
    Map<String, dynamic> rootData, {
    String? leafActionWidgetLabel,
    void Function(dynamic)? leafActionWidgetOnPressed,
    Size? leafActionWidgetSize,
  }) {
    (TreeType<SimpleTreeNode>, int) buildNodes(
      Map<String, dynamic> data,
      TreeType<SimpleTreeNode>? parent,
      int level,
      int currentIndex,
    ) {
      int nextIndex = currentIndex + 1;
      double padding = level * 16;
      Color nodeBgColor = currentIndex % 2 == 0
          ? Color(0xFF171C22)
          : Color(0xFF23282D);
      var node = TreeType<SimpleTreeNode>(
        data: SimpleTreeNode(
          id: data["id"],
          title: data["name"],
          level: level,
          index: currentIndex,
          nodeBgColor: nodeBgColor,
          padding: padding,
          isShowCheckbox: false,
          onSelected: (v) {
            GlobalLogger.logInfo(v.toString());
          },
          isChosen: false,
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
        node.data.isInner = false;
        // node.data.isShowCheckbox = true;
        node.data.padding = node.data.padding + 10;
        node.data.titleIcon = HyIcons.wenjian;

        if (leafActionWidgetLabel != null) {
          node.data.leafActionWidgetLabel = leafActionWidgetLabel;
        }
        if (leafActionWidgetOnPressed != null) {
          node.data.leafActionWidgetOnPressed = leafActionWidgetOnPressed;
        }
        if (leafActionWidgetSize != null) {
          node.data.leafActionWidgetSize = leafActionWidgetSize;
        }
      }
      return (node, nextIndex);
    }

    // 从根节点开始，层级为1，索引从0开始
    var (rootNode, _) = buildNodes(rootData, null, 0, 0);
    return rootNode;
  }

  TreeType<SimpleTreeNode> sampleVNRegionNode<T extends AbsNodeType>(
    Map<String, Map<String, Object>> vnJson,
  ) {
    int index = 0;
    var root = TreeType<SimpleTreeNode>(
      data: SimpleTreeNode(id: 0, title: "Việt Nam", level: 1, index: index),
      children: [],
      parent: null,
    );

    for (Map<String, dynamic> province in vnJson.values) {
      index = index + 1;
      var newProvince = TreeType<SimpleTreeNode>(
        data: SimpleTreeNode(
          id: province["code"],
          title: province["name"],
          level: 1,
          index: index,
          padding: 16,
        ),
        children: [],
        parent: root,
      );

      root.children.add(newProvince);

      for (Map<String, dynamic> district
          in (province["quan-huyen"] as Map).values) {
        index = index + 1;
        var newDistrict = TreeType<SimpleTreeNode>(
          data: SimpleTreeNode(
            id: district["code"],
            title: district["name"],
            level: 2,
            index: index,
            padding: 16 * 2,
          ),
          children: [],
          parent: newProvince,
        );

        newProvince.children.add(newDistrict);

        for (Map<String, dynamic> ward
            in (district["xa-phuong"] as Map).values) {
          index = index + 1;
          var newWard = TreeType<SimpleTreeNode>(
            data: SimpleTreeNode(
              id: ward["code"],
              title: ward["name"],
              level: 3,
              isInner: false,
              index: index,
              padding: 16 * 3 + 16 + 10,
            ),
            children: [],
            parent: newDistrict,
          );

          newDistrict.children.add(newWard);
        }
      }
    }

    return root;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
}
