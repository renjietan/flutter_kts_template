import 'package:flutter/cupertino.dart';
import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';

class SimpleTreeNode extends AbsNodeType {
  SimpleTreeNode({
    required dynamic id,
    required dynamic title,
    bool isInner = true,
    this.level = 0,
    this.index = 0,
    this.padding = 0,
    this.isExpanded = true,
    this.isShowCheckbox = false,
    this.titleIcon,
    this.leafActionWidgetLabel,
    this.leafActionWidgetOnPressed,
    this.leafActionWidgetSize,
  }) : super(id: id, title: title, isInner: isInner, isExpanded: isExpanded);

  int level;
  double padding;
  int index;
  bool isExpanded;
  bool isShowCheckbox;
  IconData? titleIcon;
  String? leafActionWidgetLabel;
  void Function(dynamic)? leafActionWidgetOnPressed;
  Size? leafActionWidgetSize;

  @override
  T clone<T extends AbsNodeType>() {
    var newData = SimpleTreeNode(
      id: id,
      title: title,
      isInner: isInner,
      level: level,
      padding: padding,
      index: index,
      isExpanded: isExpanded,
      isShowCheckbox: isShowCheckbox,
      titleIcon: titleIcon,
      leafActionWidgetLabel: leafActionWidgetLabel,
      leafActionWidgetOnPressed: leafActionWidgetOnPressed,
      leafActionWidgetSize: leafActionWidgetSize,
    );
    newData.isUnavailable = isUnavailable;
    newData.isChosen = isChosen;
    newData.isExpanded = isExpanded;
    newData.isFavorite = isFavorite;

    return newData as T;
  }
}
