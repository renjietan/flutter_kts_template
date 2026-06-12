import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reorderable_tree_list_view/reorderable_tree_list_view.dart';

import '../../icons/hy_icons.dart';

class TreeView extends StatefulWidget {
  final List<Uri> paths;
  const TreeView({super.key, required this.paths});

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  List<Uri> paths = [
    Uri.parse('file:///documents/1'),
    Uri.parse('file:///documents/images/2'),
    Uri.parse('file:///documents/images/3'),
    Uri.parse('file:///downloads/1'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/2'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/3'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/4'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/5'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/6'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/7'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/8'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/9'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/10'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/11'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/12'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/13'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/14'),
    Uri.parse('file:///downloads/music/5'),
    Uri.parse('file:///downloads/15'),
    Uri.parse('file:///downloads/music/5'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Theme(
            data: ThemeData.dark(),
            child: ReorderableTreeListView(
              enableDragAndDrop: false,
              // 键盘导航
              enableKeyboardNavigation: true,
              theme: TreeTheme(
                indentSize: 25.0.w,
                itemPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: BorderRadius.circular(8),
              ),
              paths: paths,
              initiallyExpanded: {
                Uri.parse('file:///documents/images/2'),
                // Uri.parse('file:///documents/images/2'),
                // Uri.parse('file:///documents/images/3'),
                // Uri.parse('file:///downloads/4'),
                // Uri.parse('file:///downloads/music/5'),
              },
              itemBuilder: (context, path) => Row(
                children: [
                  Icon(HyIcons.wenjian, size: 20),
                  SizedBox(width: 8),
                  Text(TreePath.getDisplayName(path)),
                  const Spacer(),
                  Text("按钮"),
                ],
              ),
              folderBuilder: (context, path) => Row(
                children: [
                  Icon(HyIcons.ren, size: 20, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    TreePath.getDisplayName(path),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onItemTap: (Uri path) {
                print(path);
              },
              onReorder: (oldPath, newPath) {
                setState(() {
                  paths.remove(oldPath);
                  paths.add(newPath);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
