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
  String get netNOdePath =>
      p.join(dataPath, "4_net_node", "$selectMasterId.json");
  String get resourcePath => p.join(dataPath, "1_resource");

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
    SimplePopup.loading();
    String dcJsonFilePath = p.join(
      dataPath,
      "3_device_config",
      "${v.title}.json",
    );
    String savePath = await DirectoryManager.instance.getZipCache();
    String resPath = "";
    List<String> resourceFileNames = await FileTools.getJsonFileNameByFPath(
      resourcePath,
    );
    List<ArchiveEntry> resourceEntries = resourceFileNames
        .fold<List<ArchiveEntry>>([], (cur, pre) {
          ArchiveEntry temp = ArchiveEntry(
            sourcePath: p.join(dataPath, "1_resource", pre),
            innerDir: "1_resource",
          );
          cur.add(temp);
          return cur;
        });
    try {
      if (v.title.startsWith("dc_ccu_")) {
        // 构建 ccu 打包的文件列表: 1_resource、3_device_config、4_net_node
        List<ArchiveEntry> entries = [
          ...resourceEntries,
          ArchiveEntry(sourcePath: dcJsonFilePath, innerDir: "3_device_config"),
          ArchiveEntry(sourcePath: netNOdePath, innerDir: "4_net_node"),
        ];
        String ccuTarPath = await FileTools.filesToZipFormPath(
          entries: entries,
          outputPath: savePath,
          zipName: "ccu",
        );
        resPath = ccuTarPath;
      } else if (v.title.startsWith("dc_server")) {
        // 构建 server 打包的文件列表: 1_resource、2_radio_subnet、3_device_config、4_net_node、5_user、6_contacts
        List<Directory> subFolds = await FileTools.getDirectSubFolders(
          dataPath,
        );
        String serviceTarPath = await FileTools.filesToZipFormListDirectory(
          subFolds,
          outputPath: savePath,
          zipName: "server",
        );
        resPath = serviceTarPath;
      } else {
        // 构建 radio 打包的文件列表: 1_resource、2_radio_subnet、3_device_config、4_net_node
        // 读取文件内容
        Map<String, dynamic> dcContent = FileTools.readFileContentAsMap(
          dcJsonFilePath,
        );
        Map<String, dynamic>? dcChannels = dcContent["Channels"] ?? {};
        // 根据 3_device_config 中的 Channels 字段 获取 Subnets 列表，后续 将 根据 Subnets 字段 查找 2_radio_subnet 问价
        List<String> dcChannelsValues = (dcChannels?.values.toList() ?? [])
            .fold<List<String>>([], (cur, pre) {
              String subnet = pre["Subnet"] ?? '';
              if (subnet.isNotEmpty) {
                cur.add("$subnet.json");
              }
              return cur;
            })
            .toList();
        // 汇总 4_net_node + 3_device_config + 2_radio_subnet + 1_resource
        List<ArchiveEntry> entries = dcChannelsValues.fold<List<ArchiveEntry>>(
          [
            ...resourceEntries,
            ArchiveEntry(
              sourcePath: dcJsonFilePath,
              innerDir: "3_device_config",
            ),
            ArchiveEntry(sourcePath: netNOdePath, innerDir: "4_net_node"),
          ],
          (cur, pre) {
            String sourcePath = p.join(dataPath, "2_radio_subnet", pre);
            ArchiveEntry temp = ArchiveEntry(
              sourcePath: sourcePath,
              innerDir: "2_radio_subnet",
            );
            cur.add(temp);
            return cur;
          },
        );
        String serviceTarPath = await FileTools.filesToZipFormPath(
          entries: entries,
          outputPath: savePath,
          zipName: "radios",
        );
        resPath = serviceTarPath;
      }
      await SimpleAsyncPopup.hideLoading(Duration(milliseconds: 500));
      SimpleAsyncPopup.success(
        t.common.OperationSuccess,
        duration: Duration(milliseconds: 700),
      );
    } catch (e) {
      GlobalLogger.logError("paramsInject.mixin: ${e.toString()}");
      await SimpleAsyncPopup.hideLoading(Duration(milliseconds: 500));
      SimpleAsyncPopup.error(
        t.common.OperationError,
        timeout: Duration(milliseconds: 700),
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
