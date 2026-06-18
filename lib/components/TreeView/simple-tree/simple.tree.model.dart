import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';

class SimpleTreeNode extends AbsNodeType {
  SimpleTreeNode({
    required dynamic id,
    required dynamic title,
    bool isInner = true,
    this.level = 0,
    this.index = 0,
    this.padding = 0,
    this.IsExpand = true,
  }) : super(id: id, title: title, isInner: isInner, isExpanded: IsExpand);

  int level;
  double padding;
  int index;
  bool IsExpand;

  @override
  T clone<T extends AbsNodeType>() {
    var newData = SimpleTreeNode(
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
