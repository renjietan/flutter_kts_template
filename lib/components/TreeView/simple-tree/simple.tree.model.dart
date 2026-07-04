import 'package:flutter/cupertino.dart';
import 'package:recursive_tree_flutter/recursive_tree_flutter.dart';

class SimpleTreeNode extends AbsNodeType {
  SimpleTreeNode({
    required dynamic id,
    required dynamic title,
    bool isInner = true,
    bool isChosen = false,
    this.level = 0,
    this.index = 0,
    this.padding = 0,
    this.expanded = true,
    this.titleIcon,
    this.leafActionWidgetLabel,
    this.leafActionWidgetOnPressed,
    this.leafActionWidgetSize,
    this.nodeBgColor,
    this.activeSelection,
    this.isShowCheckbox = false,
  }) : super(
         id: id,
         title: title,
         isInner: isInner,
         isExpanded: expanded,
         isChosen: isChosen,
       );

  int level;
  double padding;
  int index; // 节点下标，用于实现斑马线
  bool expanded; // 节点是否需要展开
  bool isShowCheckbox; // 叶子节点是否需要 checkbox
  IconData? titleIcon; // 节点图标
  String? leafActionWidgetLabel; // 叶子节点文字
  void Function(AbsNodeType)? leafActionWidgetOnPressed; // 叶子节点  右侧widget的点击事件
  Size? leafActionWidgetSize;
  Color? nodeBgColor;
  bool? activeSelection; // 是否选中，用于判断选中后变色

  @override
  T clone<T extends AbsNodeType>() {
    var newData = SimpleTreeNode(
      id: id,
      title: title,
      isInner: isInner,
      level: level,
      // padding: padding,
      // index: index,
      // isExpanded: isExpanded,
      // isShowCheckbox: isShowCheckbox,
      // titleIcon: titleIcon,
      // leafActionWidgetLabel: leafActionWidgetLabel,
      // leafActionWidgetOnPressed: leafActionWidgetOnPressed,
      // leafActionWidgetSize: leafActionWidgetSize,
      // nodeBgColor: nodeBgColor,
    );
    newData.isUnavailable = isUnavailable;
    newData.isChosen = isChosen;
    newData.isExpanded = isExpanded;
    newData.isFavorite = isFavorite;

    return newData as T;
  }
}
