import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/DropDown/simple.dropdown.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.treeview.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_kts_template/pages/paramsInject/treeData/treeData.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/fileUploads/fileUploads.dart';
import '../radioManager/radio.model.dart';
import 'components/paramsFormDialog.dart';

class ParamsInjectPager extends StatefulWidget {
  const ParamsInjectPager({super.key});

  @override
  State<ParamsInjectPager> createState() => _ParamsInjectPagerState();
}

class _ParamsInjectPagerState extends State<ParamsInjectPager>
    with ParamsInjectMixin {
  UserStatus? _statusFilter;
  late TreeType<SimpleTreeNode> _tree;
  late TreeType<SimpleTreeNode> _detailTree;
  bool detailVisiable = true;

  @override
  void initState() {
    // TODO: implement initState
    _tree = buildTree(treeMockData, activeSelection: true);
    _detailTree = buildTree(
      mockData1,
      leafActionWidgetLabel: "inject",
      leafActionWidgetOnPressed: (v) {
        GlobalLogger.logInfo(v.toString());
        ParamsFormDialog.showDialog(
          title: "111",
          fields: [],
          onConfirm: (v) {
            print(v);
          },
        );
      },
      leafActionWidgetSize: Size(70, 30),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeData.dark().primaryColorDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: _buildMasterTree(context)),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(flex: 3, child: _buildDetailTree("SCC-Command Vehicle-1")),
        ],
      ),
    );
  }

  /// master tree
  Widget _buildMasterTree(BuildContext ctx) {
    final t = Translations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(16, 10, 0, 0),
          child: TextTitle(text: t.pager.radioManager.fileParse),
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
                    child: Row(
                      children: [
                        Text(
                          t.pager.radioManager.netNode,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
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
                    child: SingleChildScrollView(
                      child: SimpleTreeView(
                        _tree,
                        onNodeDataChanged: (v) async {
                          setState(() {
                            detailVisiable = false;
                          });
                          Map<String, dynamic> data = v.data.title == "张小明"
                              ? mockData1
                              : mockData2;
                          data["name"] =
                              data["name"] + DateTime.now().second.toString();
                          TreeType<SimpleTreeNode> temp = buildTree(
                            data,
                            leafActionWidgetLabel:
                                v.data.titleIcon == HyIcons.ren
                                ? null
                                : "inject",
                            leafActionWidgetOnPressed:
                                v.data.titleIcon == HyIcons.ren
                                ? null
                                : (v) {
                                    GlobalLogger.logInfo(
                                      "inject value: ${v.toString()}",
                                    );
                                  },
                            leafActionWidgetSize: Size(70, 30),
                          );
                          _detailTree = temp;
                          Future.delayed(Duration(milliseconds: 100)).then((_) {
                            setState(() {
                              detailVisiable = true;
                            });
                          });
                        },
                      ),
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

  /// detail tree
  Widget _buildDetailTree(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsetsGeometry.fromLTRB(12, 10, 10, 10),
          padding: const EdgeInsetsGeometry.only(left: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(width: 5, color: Color(0xFF00A2E9)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextTitle(text: title),
              BaseButton(label: t.button.radioManager.save, width: 65),
            ],
          ),
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
              child: SingleChildScrollView(
                child: Visibility(
                  visible: detailVisiable,
                  child: SimpleTreeView(
                    _detailTree,
                    onNodeDataChanged: (v) {
                      GlobalLogger.logInfo(v.toString());
                      // 什么都不干，也必须 setState，否则无法实时更新 tree
                      setState(() {});
                    },
                  ),
                ),
                // child: SimpleTreeView(
                //   _detailTree,
                //   onNodeDataChanged: (v) {
                //     GlobalLogger.logInfo(v.toString());
                //   },
                // ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
