import 'package:flutter/material.dart';
import 'package:reorderable_tree_list_view/reorderable_tree_list_view.dart';

class TestTreeView extends StatefulWidget {
  const TestTreeView({super.key});

  @override
  State<TestTreeView> createState() => _TestTreeViewState();
}

class _TestTreeViewState extends State<TestTreeView> {
  List<Uri> paths = [
    Uri.parse('file:///documents/report.pdf'),
    Uri.parse('file:///documents/images/photo1.jpg'),
    Uri.parse('file:///documents/images/photo2.jpg'),
    Uri.parse('file:///downloads/app.zip'),
    Uri.parse('file:///downloads/music/song.mp3'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Row(
      children: [
        Expanded(child: ReorderableTreeListView(
          paths: paths,
          initiallyExpanded: {
            Uri.parse('file:///documents/report.pdf'),
            Uri.parse('file:///documents/images/photo1.jpg'),
            Uri.parse('file:///documents/images/photo2.jpg'),
            Uri.parse('file:///downloads/app.zip'),
            Uri.parse('file:///downloads/music/song.mp3'),
          },
          itemBuilder: (context, path) => Row(
            children: [
              Icon(Icons.insert_drive_file, size: 20),
              SizedBox(width: 8),
              Text(TreePath.getDisplayName(path)),
            ],
          ),
          folderBuilder: (context, path) => Row(
            children: [
              Icon(Icons.folder, size: 20, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                TreePath.getDisplayName(path),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          onReorder: (oldPath, newPath) {
            setState(() {
              paths.remove(oldPath);
              paths.add(newPath);
            });
          },
        ))
      ],
    ));
  }
}