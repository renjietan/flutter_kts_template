import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/FileUploads/fileUploads.dart';
import 'package:flutter_kts_template/components/TextField/simple.filter.search.textField.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.treeview.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:recursive_tree_flutter/functions/tree_update_functions.dart';

class ParamsInjectPager extends StatefulWidget {
  const ParamsInjectPager({super.key});

  @override
  State<ParamsInjectPager> createState() => _ParamsInjectPagerState();
}

class _ParamsInjectPagerState extends State<ParamsInjectPager>
    with ParamsInjectMixin {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    resetMasterTree();
    resetDetailTree();
    initLeftTree(null);
    initUdp();
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
          Expanded(flex: 3, child: _buildDetailTree()),
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
        FileUploads(
          onUpdate: (String path) {
            initLeftTree(path);
          },
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
                      child: SimpleFilterSearchField(
                        value: searchValue,
                        onChanged: (v) {
                          updateTreeWithSearchingTitle(masterTreeData, v);
                          setState(() {});
                        },
                        controller: searchTextFieldController,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Visibility(
                        visible: masterVisible,
                        child: SimpleTreeView(
                          masterTreeData,
                          onNodeDataChanged: masterTreeOnSelect,
                        ),
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
  Widget _buildDetailTree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsGeometry.fromLTRB(12, 15, 10, 15),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(width: 5, color: Color(0xFF00A2E9)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 15),
                TextTitle(text: selectMasterId),
                // BaseButton(label: t.button.radioManager.save, width: 65),
              ],
            ),
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
              child: Visibility(
                visible: detailVisible,
                child: ListView.builder(
                  itemCount: detailTreeData.length,
                  itemBuilder: (context, index) {
                    return SimpleTreeView(
                      detailTreeData[index],
                      onNodeDataChanged: (v) {
                        GlobalLogger.logInfo(v.toString());
                        // 什么都不干，也必须 setState，否则无法实时更新 tree
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
