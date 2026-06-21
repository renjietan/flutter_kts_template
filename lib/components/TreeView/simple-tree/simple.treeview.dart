import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart';
import 'package:recursive_tree_flutter/functions/tree_update_functions.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:recursive_tree_flutter/views/expandable_tree_mixin.dart';

import '../../../logger/logger.dart';
import '../../button/base.button.dart';

class SimpleTreeView extends StatefulWidget {
  final TreeType<SimpleTreeNode> tree;

  final VoidCallback onChecked;

  const SimpleTreeView(this.tree, {super.key, required this.onChecked});

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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [buildNode(), buildChildrenNodes()],
    );
  }

  @override
  Widget buildNode() {
    if (!widget.tree.data.isShowedInSearching) return const SizedBox.shrink();
    Color colorByLevel = widget.tree.data.index % 2 == 0
        ? Color(0xFF171C22)
        : Color(0xFF23282D);
    if (widget.tree.data.title == "张伟") {
      GlobalLogger.logInfo(
        "张伟：${widget.tree.data.leafActionWidgetOnPressed.toString()}",
      );
    }
    return InkWell(
      onTap: updateStateToggleExpansion,
      child: Container(
        color: colorByLevel,
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: tree.isLeaf
                    ? widget.tree.data.padding + 26
                    : widget.tree.data.padding,
              ),
              child: widget.tree.children.isNotEmpty
                  ? buildRotationIcon()
                  : const SizedBox.shrink(),
            ),
            if (widget.tree.data.titleIcon != null)
              Icon(widget.tree.data.titleIcon, color: Colors.white, size: 16),
            SizedBox(width: 10),
            Expanded(child: buildTitle()),
            if (widget.tree.data.leafActionWidgetLabel != null && tree.isLeaf)
              BaseButton(
                label: widget.tree.data.leafActionWidgetLabel!,
                width: widget.tree.data.leafActionWidgetSize?.width ?? 70,
                onPressed: () {
                  if (widget.tree.data.leafActionWidgetOnPressed != null) {
                    widget.tree.data.leafActionWidgetOnPressed!(
                      widget.tree.data,
                    );
                  }
                },
              ),
            if (tree.isLeaf && widget.tree.data.isShowCheckbox) buildTrailing(),
            SizedBox(width: 10),
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
        value: tree.data.isChosen!,
        onChanged: (value) {
          updateTreeSingleChoice(tree, !tree.data.isChosen!);
          widget.onChecked();
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
    (int index) => SimpleTreeView(list[index], onChecked: widget.onChecked),
  );

  @override
  void updateStateToggleExpansion() => setState(() => toggleExpansion());
}
