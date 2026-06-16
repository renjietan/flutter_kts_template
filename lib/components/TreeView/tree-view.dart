import 'package:flutter/material.dart';
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
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Color(0xFF171C22), // 改变列表背景
      ),
      child: FutureBuilder(
        future: widget.future(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              color: Colors.black,
              child: ReorderableTreeListView(
                // 键盘导航
                enableKeyboardNavigation: true,
                theme: TreeTheme(
                  indentSize: 15.0,
                  itemPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
              ),
            );
          }
          return Center(child: buildEmptyWidget());
        },
      ),
    );
  }
}

Widget buildEmptyWidget() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.filter_none, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            'No Data found',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}
