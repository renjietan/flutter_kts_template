import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart';
import 'package:recursive_tree_flutter/functions/tree_update_functions.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:recursive_tree_flutter/views/expandable_tree_mixin.dart';

class SimpleTreeView extends StatefulWidget {
  const SimpleTreeView(this.tree, {super.key, required this.onNodeDataChanged});

  final TreeType<SimpleTreeNode> tree;

  final VoidCallback onNodeDataChanged;

  @override
  State<SimpleTreeView> createState() => _SimpleTreeViewState();
}

class _SimpleTreeViewState<T extends AbsNodeType> extends State<SimpleTreeView>
    with SingleTickerProviderStateMixin, ExpandableTreeMixin<SimpleTreeNode> {
  final Tween<double> _turnsTween = Tween<double>(begin: -0.25, end: 0.0);
  late int count = 0;

  @override
  initState() {
    super.initState();
    initTree();
    initRotationController();
    if (tree.data.isExpanded) {
      rotationController.forward();
    }
  }

  @override
  void initTree() {
    tree = widget.tree;
  }

  @override
  void initRotationController() {
    rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.disposeRotationController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildView();

  @override
  Widget buildNode() {
    if (!widget.tree.data.isShowedInSearching) return const SizedBox.shrink();
    Color colorByLevel = widget.tree.data.index % 2 == 0
        ? Color(0xFF171C22)
        : Color(0xFF23282D);
    Widget wd = widget.tree.data.index % 2 == 0
        ? Icon(Icons.one_k_outlined, color: Colors.white, size: 16)
        : Icon(Icons.file_copy, color: Colors.white, size: 16);
    return InkWell(
      onTap: updateStateToggleExpansion,
      child: Container(
        color: colorByLevel,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: widget.tree.data.padding),
              child: buildRotationIcon(),
            ),
            wd,
            SizedBox(width: 10),
            Expanded(child: buildTitle()),
            buildTrailing(),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildChildrenNodes({
    final EdgeInsets? padding = const EdgeInsets.only(left: 0),
  }) {
    return SizeTransition(
      sizeFactor: rotationController,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(children: generateChildrenNodesWidget(tree.children)),
      ),
    );
  }

  Widget buildRotationIcon() {
    return RotationTransition(
      turns: _turnsTween.animate(rotationController),
      child: tree.isLeaf
          ? Container()
          : IconButton(
              iconSize: 16,
              icon: const Icon(
                Icons.expand_more,
                size: 16.0,
                color: Colors.white,
              ),
              onPressed: updateStateToggleExpansion,
            ),
    );
  }

  Widget buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Text(
        tree.data.title + (tree.isLeaf ? "" : " (${tree.children.length})"),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget buildTrailing() {
    if (tree.data.isUnavailable) {
      return const Icon(Icons.close_rounded, color: Colors.red);
    }

    if (tree.isLeaf) {
      return Checkbox(
        value: tree.data.isChosen!, // leaves always is true or false
        onChanged: (value) {
          updateTreeSingleChoice(tree, !tree.data.isChosen!);
          widget.onNodeDataChanged();
        },
      );
    }

    return const SizedBox.shrink();
  }

  @override
  List<Widget> generateChildrenNodesWidget(
    List<TreeType<SimpleTreeNode>> list,
  ) => List.generate(
    list.length,
    (int index) => SimpleTreeView(
      list[index],
      onNodeDataChanged: widget.onNodeDataChanged,
    ),
  );

  @override
  void updateStateToggleExpansion() => setState(() => toggleExpansion());
}
