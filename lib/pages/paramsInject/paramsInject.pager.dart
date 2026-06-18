import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/DropDown/simple.dropdown.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:reorderable_tree_list_view/reorderable_tree_list_view.dart';

import '../../components/TreeView/tree-view.dart';
import '../../components/fileUploads/fileUploads.dart';
import '../../icons/hy_icons.dart';
import '../radioManager/radio.model.dart';

class ParamsInjectPager extends StatefulWidget {
  const ParamsInjectPager({super.key});

  @override
  State<ParamsInjectPager> createState() => _ParamsInjectPagerState();
}

class _ParamsInjectPagerState extends State<ParamsInjectPager>
    with ParamsInjectMixin {
  UserStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeData.dark().primaryColorDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: _buildMasterTree(getTreeData)),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            flex: 3,
            child: _buildDetailTree(getTreeData, "SCC-Command Vehicle-1"),
          ),
        ],
      ),
    );
  }

  /// leftTree
  Widget _buildMasterTree(Future<List<Uri>> Function() future) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(16, 10, 0, 0),
          child: TextTitle(text: "File Parse"),
        ),
        const FileUploads(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF171C22),
                border: Border.all(
                  width: 1,
                  color: Color(0x8A00A2E9),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(16, 5, 0, 10),
                    child: Text("Net Node", style: TextStyle(fontSize: 14)),
                  ),
                  DataTablePlusThemeProvider(
                    theme: getThemePreset(ThemePreset.dark),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      child: SimpleDropdown(
                        value: _statusFilter,
                        hint: '',
                        items: UserStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.name[0].toUpperCase() + s.name.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: TreeView(
                      future: future,
                      folderBuilder: (context, path) {
                        return Row(
                          children: [
                            Icon(HyIcons.ren, size: 14, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              TreePath.getDisplayName(path),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                      itemBuilder: (context, path) {
                        return Row(
                          children: [
                            Icon(HyIcons.jiantou, size: 20),
                            SizedBox(width: 8),
                            Text(TreePath.getDisplayName(path)),
                            const Spacer(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTree(Future<List<Uri>> Function() future, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsetsGeometry.fromLTRB(12, 10, 0, 10),
          padding: const EdgeInsetsGeometry.only(left: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(width: 5, color: Color(0xFF00A2E9)),
            ),
          ),
          child: TextTitle(text: title),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF171C22),
                border: Border.all(
                  width: 1,
                  color: Color(0x8A00A2E9),
                  style: BorderStyle.solid,
                ),
              ),
              child: TreeView(
                future: future,
                folderBuilder: (context, path) {
                  return Row(
                    children: [
                      Icon(HyIcons.ren, size: 14, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        TreePath.getDisplayName(path),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
                itemBuilder: (context, path) {
                  return Row(
                    children: [
                      Icon(HyIcons.wenjian, size: 16),
                      SizedBox(width: 8),
                      Text(TreePath.getDisplayName(path)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
