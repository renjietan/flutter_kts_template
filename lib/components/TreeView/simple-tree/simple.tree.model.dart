import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';

class TreeNode extends AbsNodeType {
  TreeNode({
    required dynamic id,
    required dynamic title,
    bool isInner = true,
    this.level = 0,
    this.index = 0,
    this.padding = 0,
  }) : super(id: id, title: title, isInner: isInner, isExpanded: true);

  int level;
  double padding;
  int index;

  @override
  T clone<T extends AbsNodeType>() {
    var newData = TreeNode(
      id: id,
      title: title,
      isInner: isInner,
      level: level,
    );
    newData.isUnavailable = isUnavailable;
    newData.isChosen = isChosen;
    newData.isExpanded = isExpanded;
    newData.isFavorite = isFavorite;
    return newData as T;
  }
}
