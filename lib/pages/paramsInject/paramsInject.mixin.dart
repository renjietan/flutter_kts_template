import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.tools.dart';
import 'package:path/path.dart' as p;
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/FileUploads/fileUploads.mixin.dart';
import '../../components/TreeView/simple-tree/simple.tree.model.dart';
import '../../components/loading/simple.async.loading.dart';
import '../../components/loading/simple.loading.dart';
import '../../core/utils/director.dart';
import '../../i18n/handle/translations.g.dart';
import '../../logger/logger.dart';
import '../../utils/files/FileTools.dart';

mixin ParamsInjectMixin<T extends StatefulWidget> on State<T> {
  Map<String, dynamic> allData = {};
  String dataPath = "";
  String searchValue = "";
  bool masterVisible = false;
  TextEditingController searchTextFieldController = TextEditingController();
  TreeType<SimpleTreeNode> masterTreeData = TreeType(
    data: SimpleTreeNode(id: "1", title: "<>"),
    children: [],
    parent: null,
  );

  late List<TreeType<SimpleTreeNode>> detailTreeData = [
    TreeType(
      data: SimpleTreeNode(id: "1", title: "<>"),
      children: [],
      parent: null,
    ),
  ];
  bool detailVisible = false;
  String detailTitle = "";
  String selectMasterId = "";

  (TreeType<SimpleTreeNode>, int) buildTree(
    Map<String, dynamic> rootData, {
    String? leafActionWidgetLabel,
    void Function(dynamic)? leafActionWidgetOnPressed,
    Size? leafActionWidgetSize,
    bool? activeSelection,
    int? startIndex,
  }) {
    (TreeType<SimpleTreeNode>, int) buildNodes(
      Map<String, dynamic> data,
      TreeType<SimpleTreeNode>? parent,
      int level,
      int currentIndex,
    ) {
      int nextIndex = data["title"] == t.tree.empty
          ? currentIndex
          : currentIndex + 1;
      double padding = level * 16;
      Color nodeBgColor = currentIndex % 2 == 0
          ? Color(0xFF171C22)
          : Color(0xFF23282D);
      var node = TreeType<SimpleTreeNode>(
        data: SimpleTreeNode(
          id: data["id"],
          title: data["title"],
          level: level,
          index: currentIndex,
          nodeBgColor: nodeBgColor,
          padding: padding,
        ),
        children: [],
        parent: parent,
      );

      final rawChildren = (data['children'] ?? []) as List<dynamic>;
      List<TreeType<SimpleTreeNode>> childNodes = [];
      for (var childData in rawChildren) {
        if (childData is Map<String, dynamic>) {
          var (childNode, newIndex) = buildNodes(
            childData,
            node,
            level + 1,
            nextIndex,
          );
          childNodes.add(childNode);
          nextIndex = newIndex;
        }
      }
      node.children = childNodes;
      if (node.children.isEmpty) {
        node.data.isInner = !data["isleaf"];
        node.data.isShowCheckbox = true;
        node.data.padding = node.data.padding + 10;
        node.data.titleIcon = getTreeNodeIcon(data["type"]);
        node.data.isShowCheckbox = data["isShowCheckbox"] ?? false;
        node.data.isChosen = data["isChosen"] ?? false;
        if (leafActionWidgetLabel != null) {
          node.data.leafActionWidgetLabel = leafActionWidgetLabel;
        }
        if (leafActionWidgetOnPressed != null) {
          node.data.leafActionWidgetOnPressed = leafActionWidgetOnPressed;
        }
        if (leafActionWidgetSize != null) {
          node.data.leafActionWidgetSize = leafActionWidgetSize;
        }
        if (activeSelection != null) {
          node.data.activeSelection = activeSelection;
        }
      }
      return (node, nextIndex);
    }

    // 从根节点开始，层级为1，索引从0开始
    var (rootNode, nIndex) = buildNodes(rootData, null, 0, startIndex ?? 0);
    return (rootNode, nIndex);
  }

  IconData getTreeNodeIcon(int type) {
    IconData res;
    switch (type) {
      case 1: // 指挥所
        res = HyIcons.zhihuisuo;
        break;
      case 2: // 车
        res = HyIcons.che;
        break;
      case 4: // 未来战士
        res = HyIcons.ren;
        break;
      default:
        res = HyIcons.wenjian;
    }
    return res;
  }

  void resetMasterTree() {
    masterTreeData = TreeType(
      data: SimpleTreeNode(id: "1", title: "<>"),
      children: [],
      parent: null,
    );
  }

  void resetDetailTree() {
    detailTreeData = [
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
        detailVisible = true;
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
        final (data, _) = buildTree(temp, activeSelection: true);
        masterTreeData = data;
        GlobalLogger.logInfo(masterTreeData.toString());
        masterVisible = true;
      });
    }
  }

  Future<void> masterTreeOnSelect(v) async {
    var id = v.data.id;
    if (selectMasterId == id) {
      return;
    }
    selectMasterId = id;
    detailTitle = v.data.title;
    setState(() {
      detailVisible = false;
    });
    Map<String, dynamic> netNodes = allData["net_node"][id] ?? {};
    Map<String, dynamic> netNodesSystemConfig =
        netNodes["SystemConfiguration"] ?? {};
    Map<String, dynamic> lANMember = netNodesSystemConfig["LANMember"] ?? {};
    Map<String, dynamic> lANPrimary = netNodesSystemConfig["LANPrimary"] ?? {};
    Map<String, dynamic> radio = netNodesSystemConfig["Radio"] ?? {};
    Map<String, dynamic> lANMemberTreeData = detail2TreeNode(
      allData,
      lANMember,
      "LANMember",
    );
    Map<String, dynamic> lANPrimaryTreeData = detail2TreeNode(
      allData,
      lANPrimary,
      "LANPrimary",
    );
    Map<String, dynamic> radioTreeData = detail2TreeNode(
      allData,
      radio,
      "Radio",
    );
    List<TreeType<SimpleTreeNode>> temp = [];
    [lANMemberTreeData, lANPrimaryTreeData, radioTreeData].fold(0, (cur, pre) {
      pre = transformUnitTree(pre, fillNode: false);
      final (data, nIndex) = buildTree(
        pre,
        leafActionWidgetLabel: v.data.titleIcon == HyIcons.ren
            ? null
            : "inject",
        leafActionWidgetOnPressed: v.data.titleIcon == HyIcons.ren
            ? null
            : detailsTreeOnTap,
        leafActionWidgetSize: Size(70, 30),
        startIndex: cur,
      );
      temp.add(data);
      cur = nIndex;
      return cur;
    });
    detailTreeData = temp;
    Future.delayed(Duration(milliseconds: 100)).then((_) {
      setState(() {
        detailVisible = true;
      });
    });
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

  Future<void> detailsTreeOnTap(v) async {
    String netNOdePath = p.join(dataPath, "4_net_node", "$selectMasterId.json");
    String dcPath = p.join(dataPath, "3_device_config", "${v.title}.json");
    String savePath = await DirectoryManager.instance.getZipCache();
    try {
      SimplePopup.loading();
      if (v.title.startsWith("dc_ccu_")) {
        String ccuTarPath = await FileTools.filesToZipFormPath(
          entries: [
            ArchiveEntry(sourcePath: netNOdePath, innerDir: "4_net_node"),
            ArchiveEntry(sourcePath: dcPath, innerDir: "3_device_config"),
          ],
          outputPath: savePath,
          zipName: "ccu",
          type: ArchiveEncoderType.tar,
        );
        print(ccuTarPath);
      } else if (v.title.startsWith("dc_server")) {
        List<Directory> subFolds = await FileTools.getDirectSubFolders(
          dataPath,
        );
        subFolds = subFolds
            .where(
              (v) => [
                "1_resource",
                "2_radio_subnet",
                "3_device_config",
                "4_net_node",
              ].any((item) => v.path.contains(item)),
            )
            .toList();
        String serviceTarPath = await FileTools.filesToZipFormListDirectory(
          subFolds,
          outputPath: savePath,
          zipName: "server",
        );
        print(dataPath);
        print(subFolds);
        print(serviceTarPath);
      }
      SimplePopup.hideLoading();
      SimpleAsyncPopup.success(t.common.OperationSuccess);
    } catch (e) {
      SimplePopup.hideLoading();
      GlobalLogger.logError("paramsInject.mixin: ${e.toString()}");
      SimpleAsyncPopup.error(
        t.common.OperationError,
        timeout: Duration(milliseconds: 200),
      );
    }

    // File DcFile = File(dcPath);
    // String dcJsonStr =
    //     DcFile.readAsStringSync();
    // var dcJson = jsonDecode(dcJsonStr);
    // print(dcJson);
    // GlobalLogger.logInfo(
    //   "inject value: ${v.toString()}",
    // );
  }
}
