import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reorderable_tree_list_view/reorderable_tree_list_view.dart';

class TreeView extends StatefulWidget {
  final Future<List<Uri>> Function() future;
  final Widget Function(BuildContext, Uri) itemBuilder;
  final Widget Function(BuildContext, Uri) folderBuilder;
  const TreeView({
    super.key,
    required this.future,
    required this.itemBuilder,
    required this.folderBuilder,
  });

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Theme(
            data: ThemeData.dark(),
            child: FutureBuilder(
              future: widget.future(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ReorderableTreeListView(
                    // 键盘导航
                    enableKeyboardNavigation: true,
                    theme: TreeTheme(
                      indentSize: 25.0.w,
                      itemPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    paths: snapshot.data as List<Uri>,
                    initiallyExpanded: {
                      Uri.parse('file://'),
                      Uri.parse("file:///documents"),
                      // Uri.parse('file:///documents/images/2'),
                      // Uri.parse('file:///documents/images/3'),
                      // Uri.parse('file:///downloads/4'),
                      // Uri.parse('file:///downloads/music/5'),
                    },
                    folderBuilder: widget.folderBuilder,
                    itemBuilder: widget.itemBuilder,
                    onItemTap: (Uri path) {
                      print(path);
                    },
                    // 是否开启拖拽事件
                    enableDragAndDrop: false,
                    // 拖拽事件
                    onReorder: (oldPath, newPath) {
                      setState(() {
                        // paths.remove(oldPath);
                        // paths.add(newPath);
                      });
                    },
                  );
                }
                return Center(
                  child: Text("no data", style: TextStyle(fontSize: 15.sp)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
