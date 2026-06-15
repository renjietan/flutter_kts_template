import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/tree-view/tree-view.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reorderable_tree_list_view/reorderable_tree_list_view.dart';

import '../../components/fileUploads/fileUploads.dart';
import '../../icons/hy_icons.dart';
import '../../theme/table.theme.dart';

class ParamsInjectPager extends StatefulWidget {
  const ParamsInjectPager({super.key});

  @override
  State<ParamsInjectPager> createState() => _ParamsInjectPagerState();
}

class _ParamsInjectPagerState extends State<ParamsInjectPager>
    with ParamsInjectMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: _buildMasterTree(getTreeData)),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          flex: 3,
          child: _buildDetailTree(getTreeData, "SCC-Command Vehicle-1"),
        ),
      ],
    );
  }
}

/// leftTree
Widget _buildMasterTree(Future<List<Uri>> Function() future) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
    ),
    child: Column(
      children: [
        DataTablePlusThemeProvider(
          theme: getThemePreset(ThemePreset.dark),
          child: FilterSearchField(
              hint: '',
              onChanged: (value) {
              },
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsetsGeometry.fromLTRB(14.w, 15.h, 0, 15.h),
            child: Text("File Parse", style: TextStyle(fontSize: 20)),
          ),
        ),
        FilePickerScreen(),
        Expanded(
          child: TreeView(
            future: future,
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
            itemBuilder: (context, path) => Row(
              children: [
                Icon(HyIcons.jiantou, size: 20),
                SizedBox(width: 8),
                Text(TreePath.getDisplayName(path)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailTree(Future<List<Uri>> Function() future, String title) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsetsGeometry.fromLTRB(14.w, 15.h, 0, 15.h),
            child: Text(title, style: TextStyle(fontSize: 20.sp)),
          ),
        ),
        Expanded(
          child: TreeView(
            future: future,
            folderBuilder: (context, path) => Row(
              children: [
                Text(
                  TreePath.getDisplayName(path),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            itemBuilder: (context, path) => Text(TreePath.getDisplayName(path)),
          ),
        ),
      ],
    ),
  );
}
