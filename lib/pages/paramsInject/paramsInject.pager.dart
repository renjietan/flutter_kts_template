import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/FileUploads/fileUploads.dart';
import 'package:flutter_kts_template/components/TextField/simple.filter.search.textField.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.tree.model.dart';
import 'package:flutter_kts_template/components/TreeView/simple-tree/simple.treeview.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/components/text/text.title.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.mixin.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.tools.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';
import 'package:flutter_kts_template/utils/files/FileTools.dart';
import 'package:path/path.dart' as p;
import 'package:recursive_tree_flutter/functions/tree_update_functions.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/FileUploads/fileUploads.mixin.dart';
import '../../core/utils/director.dart';
import '../../icons/hy_icons.dart';

class ParamsInjectPager extends StatefulWidget {
  const ParamsInjectPager({super.key});

  @override
  State<ParamsInjectPager> createState() => _ParamsInjectPagerState();
}

class _ParamsInjectPagerState extends State<ParamsInjectPager>
    with ParamsInjectMixin {
  Map<String, dynamic> allData = {};
  String dataPath = "";
  String searchValue = "";
  bool masterVisible = false;
  TextEditingController searchTextFieldController = TextEditingController();
  late TreeType<SimpleTreeNode> _tree;

  late List<TreeType<SimpleTreeNode>> _detailTree;
  bool _detailVisible = false;
  String _detailTitle = "";
  String _selectMasterId = "";

  @override
  void initState() {
    // TODO: implement initState
    resetMasterTree();
    resetDetailTree();
    initLeftTree(null);
    super.initState();
  }

  void resetMasterTree() {
    _tree = TreeType(
      data: SimpleTreeNode(id: "1", title: "<>"),
      children: [],
      parent: null,
    );
  }

  void resetDetailTree() {
    _detailTree = [
      TreeType(
        data: SimpleTreeNode(id: "1", title: "<>"),
        children: [],
        parent: null,
      ),
    ];
  }

  Future<void> initLeftTree(String? filePath) async {
    setState(() {
      masterVisible = false;
    });
    final (data, path) = await readAllDataFiles(filePath);
    allData = data;
    dataPath = path;
    if (allData.isEmpty) {
      setState(() {
        masterVisible = true;
        _detailVisible = true;
        resetMasterTree();
        resetDetailTree();
      });
      return;
    }
    Map<String, dynamic> contacts = allData["contacts"] ?? {};
    for (var key in contacts.keys) {
      Map<String, dynamic> unitTree = contacts[key]["UnitTree"] ?? {};
      if (unitTree.isEmpty) continue;
      Map<String, dynamic> temp = transformUnitTree(unitTree, fillNode: true);
      setState(() {
        _tree = buildTree(temp, activeSelection: true);
        GlobalLogger.logInfo(_tree.toString());
        masterVisible = true;
      });
    }
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
                          updateTreeWithSearchingTitle(_tree, v);
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
                          _tree,
                          onNodeDataChanged: (v) async {
                            var id = v.data.id;
                            _selectMasterId = id;
                            _detailTitle = v.data.title;
                            setState(() {
                              _detailVisible = false;
                            });
                            if (v.data.title == t.tree.empty) {
                              resetDetailTree();
                              setState(() {});
                              return;
                            }
                            Map<String, dynamic> netNodes =
                                allData["net_node"][id] ?? {};
                            Map<String, dynamic> netNodesSystemConfig =
                                netNodes["SystemConfiguration"] ?? {};
                            Map<String, dynamic> lANMember =
                                netNodesSystemConfig["LANMember"] ?? {};
                            Map<String, dynamic> lANPrimary =
                                netNodesSystemConfig["LANPrimary"] ?? {};
                            Map<String, dynamic> radio =
                                netNodesSystemConfig["Radio"] ?? {};
                            Map<String, dynamic> lANMemberTreeData =
                                detail2TreeNode(
                                  allData,
                                  lANMember,
                                  "LANMember",
                                );
                            Map<String, dynamic> lANPrimaryTreeData =
                                detail2TreeNode(
                                  allData,
                                  lANPrimary,
                                  "LANPrimary",
                                );
                            Map<String, dynamic> radioTreeData =
                                detail2TreeNode(allData, radio, "Radio");
                            _detailTree =
                                [
                                  lANMemberTreeData,
                                  lANPrimaryTreeData,
                                  radioTreeData,
                                ].map((item) {
                                  item = transformUnitTree(
                                    item,
                                    fillNode: false,
                                  );
                                  return buildTree(
                                    item,
                                    leafActionWidgetLabel:
                                        v.data.titleIcon == HyIcons.ren
                                        ? null
                                        : "inject",
                                    leafActionWidgetOnPressed:
                                        v.data.titleIcon == HyIcons.ren
                                        ? null
                                        : (v) async {
                                            String netNOdePath = p.join(
                                              dataPath,
                                              "4_net_node",
                                              "$_selectMasterId.json",
                                            );
                                            String dcPath = p.join(
                                              dataPath,
                                              "3_device_config",
                                              "${v.title}.json",
                                            );
                                            String savePath =
                                                await DirectoryManager.instance
                                                    .getZipCache();
                                            FileTools.extractZipToDisk(
                                              entries: [
                                                ArchiveEntry(
                                                  sourcePath: netNOdePath,
                                                  innerDir: "4_net_node",
                                                ),
                                                ArchiveEntry(
                                                  sourcePath: dcPath,
                                                  innerDir: "3_device_config",
                                                ),
                                              ],
                                              outputPath: savePath,
                                              zipName: "ccu",
                                              type: ArchiveEncoderType.tar,
                                            );
                                            // File DcFile = File(dcPath);
                                            // String dcJsonStr =
                                            //     DcFile.readAsStringSync();
                                            // var dcJson = jsonDecode(dcJsonStr);
                                            // print(dcJson);
                                            // GlobalLogger.logInfo(
                                            //   "inject value: ${v.toString()}",
                                            // );
                                          },
                                    leafActionWidgetSize: Size(70, 30),
                                  );
                                }).toList();
                            Future.delayed(Duration(milliseconds: 100)).then((
                              _,
                            ) {
                              setState(() {
                                _detailVisible = true;
                              });
                            });
                          },
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
              TextTitle(text: _detailTitle),
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
              child: Visibility(
                visible: _detailVisible,
                child: ListView.builder(
                  itemCount: _detailTree.length,
                  itemBuilder: (context, index) {
                    return SimpleTreeView(
                      _detailTree[index],
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

  Map<String, dynamic> detail2TreeNode(
    Map<String, dynamic> data,
    Map<String, dynamic> radioFileNames,
    String rootCodeName,
  ) {
    Iterable<String> keys = radioFileNames.keys;
    var randomId = DateTime.now().millisecond;
    var res = keys.fold(
      {
        "Unit": {"UnitId": randomId, "CodeName": rootCodeName},
        "SubUnits": [],
      },
      (cur, pre) {
        randomId = randomId + 1;
        var temp = {
          "Unit": {"UnitId": randomId, "CodeName": pre},
          "SubUnits": [],
        };
        for (var i = 0; i < radioFileNames[pre].length; i++) {
          randomId = randomId + 1;
          (temp["SubUnits"] as List).add({
            "Unit": {
              "UnitId": randomId,
              "CodeName": radioFileNames[pre][i],
              "isleaf": true,
            },
            "SubUnits": [],
          });
        }
        (cur["SubUnits"] as List).add(temp);
        return cur;
      },
    );
    return res;
  }
}
