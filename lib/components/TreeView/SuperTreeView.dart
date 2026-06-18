import 'package:flutter/cupertino.dart';
import 'package:super_tree/super_tree.dart';

class SuperTreeView extends StatefulWidget {
  final List<TreeNode<FileSystemItem>> roots;
  const SuperTreeView({super.key, required this.roots});

  @override
  State<SuperTreeView> createState() => _SuperTreeViewState();
}

class _SuperTreeViewState extends State<SuperTreeView> {
  final SuperTreeThemePreset preset = SuperTreeThemes.material();
  @override
  Widget build(BuildContext context) {
    return FileSystemSuperTree(
      roots: widget.roots,
      style: preset.treeStyle,
      iconProvider: preset.fileSystemIconProvider,
      logic: const TreeViewConfig(
        defaultSortComparator: TreeSort.foldersFirst,
      ),
    );
  }
}
