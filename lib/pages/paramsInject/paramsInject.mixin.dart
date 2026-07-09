import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/TreeView/simple-tree/simple.tree.model.dart';

mixin ParamsInjectMixin<T extends StatefulWidget> on State<T> {
  TreeType<SimpleTreeNode> buildTree(
    Map<String, dynamic> rootData, {
    String? leafActionWidgetLabel,
    void Function(dynamic)? leafActionWidgetOnPressed,
    Size? leafActionWidgetSize,
    bool? activeSelection,
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
          title: data["title"],
          level: level,
          index: currentIndex,
          nodeBgColor: nodeBgColor,
          padding: padding,
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
        node.data.isShowCheckbox = true;
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
    var (rootNode, _) = buildNodes(rootData, null, 0, 0);
    return rootNode;
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

  Future<void> initDict() async {
    // print(res);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
}
