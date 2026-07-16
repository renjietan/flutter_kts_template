import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/components/TextField/simple.form.textfield.dart';
import 'package:flutter_kts_template/core/rtc/tools/proto/pManifest.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/icons/hy_icons.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.model.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.tools.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:path/path.dart' as p;
import 'package:recursive_tree_flutter/models/tree_type.dart';

import '../../components/TreeView/simple-tree/simple.tree.model.dart';
import '../../components/dialog/simple.form.dialog.dart';
import '../../components/loading/simple.async.loading.dart';
import '../../components/loading/simple.loading.dart';
import '../../config/config.dart';
import '../../core/rtc/managers/udp/udp.manager.dart';
import '../../core/rtc/rtc.timeout.dart';
import '../../core/rtc/tools/proto/byteTools.dart';
import '../../core/rtc/tools/rtc.event.dart';
import '../../core/rtc/tools/rtc.event.type.dart';
import '../../i18n/handle/translations.g.dart';
import '../../logger/logger.dart';
import '../../utils/files/FileTools.dart';
import '../../utils/formValidator/formValidator.dart';

mixin ParamsInjectMixin<T extends StatefulWidget> on State<T> {
  Map<String, dynamic> allData = {};
  // 文件基础路径
  String dataPath = "";
  String get netNOdePath =>
      p.join(dataPath, "4_net_node", "${mtc.select.id}.json");
  String get resourcePath => p.join(dataPath, "1_resource");

  MasterTreeConfig mtc = MasterTreeConfig(
    searchValue: "",
    visible: false,
    select: MasterTreeSelectConfig(id: "", type: -1, title: ""),
    searchTextFieldController: TextEditingController(),
    data: TreeType(
      data: SimpleTreeNode(id: "1", title: "<>"),
      children: [],
      parent: null,
    ),
  );

  DetailTreeConfig dtc = DetailTreeConfig(
    data: [],
    visible: false,
    dialog: DetailTreeDialogConfig(
      deviceType: TextEditingController(),
      deviceIP: TextEditingController(),
    ),
    selectRows: {},
  );

  late UdpManager manager;
  late RadioModel udpRadiosInfo = RadioModel(
    address: "192.168.7.2:60009",
    packets: [],
    packetHeader: Uint8List.fromList([]),
    userId: null,
    tarPath: "",
  );

  // leafActionWidgetLabel 叶子节点 右侧 按钮文字
  // leafActionWidgetOnPressed 叶子节点 右侧 点击事件
  // leafActionWidgetSize 叶子节点 右侧组件宽度
  // activeSelection 是否启用 勾选框
  // 下标从 几 开始，主要用于多颗树的斑马线
  // 返回 树状列表 AND 节点总数量，用于将节点数量 传入到 下一颗树中，让多棵树的斑马线显得比较连贯
  (TreeType<SimpleTreeNode>, int) buildTree(
    Map<String, dynamic> rootData, {
    String? leafActionWidgetLabel,
    void Function(SimpleTreeNode)? leafActionWidgetOnPressed,
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
      double padding =
          level * 16 +
          (data["type"] == 4 && data["children"].length != 0 ? 24 : 0);
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
          type: data["type"],
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
    mtc.searchValue = "";
    mtc.visible = false;
    mtc.select = MasterTreeSelectConfig(id: "", type: -1, title: "");
    mtc.searchTextFieldController.text = "";
    mtc.data = TreeType(
      data: SimpleTreeNode(id: "1", title: "<>"),
      children: [],
      parent: null,
    );
    resetDetailTree();
  }

  void resetDetailTree() {
    dtc.data = [];
    dtc.visible = false;
    dtc.dialog.deviceIP.text = "";
    dtc.dialog.deviceType.text = "";
    dtc.selectRows = {};
  }

  Future<void> initLeftTree(String? filePath) async {
    setState(() {
      mtc.visible = false;
    });
    final (data, path) = await readAllDataFiles(filePath);
    allData = data;
    dataPath = path;
    if (allData.isEmpty) {
      setState(() {
        mtc.visible = true;
        dtc.visible = true;
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
        mtc.data = data;
        mtc.visible = true;
      });
    }
  }

  Future<void> masterTreeOnSelect(v) async {
    resetDetailTree();
    var id = v.data.id;
    if (mtc.select.id == id) {
      return;
    }
    mtc.select.id = id;
    mtc.select.type = v.data.type;
    mtc.select.title = v.data.title;
    setState(() {
      dtc.visible = false;
    });

    Map<String, dynamic> netNodes = allData["net_node"][id] ?? {};
    Map<String, dynamic> netNodesSystemConfig =
        netNodes["SystemConfiguration"] ?? {};
    Map<String, dynamic> lANMember = netNodesSystemConfig["LANMember"] ?? {};
    Map<String, dynamic> lANPrimary = netNodesSystemConfig["LANPrimary"] ?? {};
    Map<String, dynamic> radio = netNodesSystemConfig["Radio"] ?? {};
    Map<String, dynamic> lANMemberTreeData = {};
    if (v.data.type != 4) {
      lANMemberTreeData = detail2TreeNode(allData, lANMember, "LANMember");
    }

    Map<String, dynamic> lANPrimaryTreeData = {};
    if (v.data.type != 4) {
      lANPrimaryTreeData = detail2TreeNode(allData, lANPrimary, "LANPrimary");
    }

    Map<String, dynamic> radioTreeData = detail2TreeNode(
      allData,
      radio,
      "Radio",
    );
    List<TreeType<SimpleTreeNode>> temp = [];
    [lANMemberTreeData, lANPrimaryTreeData, radioTreeData].fold(0, (cur, pre) {
      if (pre.keys.isNotEmpty) {
        pre = transformUnitTree(
          pre,
          fillNode: false,
          isShowCheckbox: mtc.select.type == 4,
        );
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
      }
      return cur;
    });
    dtc.data = temp;
    Future.delayed(Duration(milliseconds: 100)).then((_) {
      setState(() {
        dtc.visible = true;
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

  Future<void> detailsTreeOnTap(SimpleTreeNode v) async {
    var title = v.title;
    dtc.dialog.deviceType.text = title.split("_")[1];
    dtc.dialog.deviceIP.text = "";
    SimpleFormDialog(
      title: t.Form.paramsInject.text,
      confirmText: t.Form.paramsInject.text,
      fields: [
        FormFieldConfig(
          name: 'deviceType',
          label: t.Form.paramsInject.deviceType.text,
          hintText: t.Form.paramsInject.deviceType.validatorText,
          enabled: false,
          textEditingController: dtc.dialog.deviceType,
        ),
        FormFieldConfig(
          name: 'deviceIP',
          label: t.Form.paramsInject.deviceIp.text,
          hintText: t.Form.paramsInject.deviceIp.validatorText,
          textEditingController: dtc.dialog.deviceIP,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.paramsInject.deviceIp.validatorText,
            ),
            FormValidator.ipPortValidator(
              errorText: t.Form.paramsInject.deviceIp.validatorText,
            ),
          ],
        ),
      ],
      onConfirm: (Map<String, dynamic> formValue) {
        // { deviceType, deviceIP }
        startKeyLoaders(v);
      },
    );
  }

  Future<void> preview() async {}

  Future<void> startKeyLoaders(v) async {
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
    SimplePopup.loading();
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
      udpRadiosInfo.tarPath = resPath;
      login();
    } catch (e) {
      SimplePopup.hideLoading();
      GlobalLogger.logError("paramsInject.mixin: ${e.toString()}");
      await SimpleAsyncPopup.hideLoading(Duration(milliseconds: 500));
      SimpleAsyncPopup.error(
        t.common.OperationError,
        timeout: Duration(milliseconds: 700),
      );
    }
  }

  Future<void> initUdp() async {
    manager = UdpManager();
    await manager.connect(AppConfig.udpConfig.toString());
    manager.eventStream.listen((RtcEvent v) {
      if (v.type == RtcEventType.closed) {
        SimplePopup.error(t.udp.closed);
      } else if (v.type == RtcEventType.created) {
        GlobalLogger.logInfo("Udp start :${AppConfig.udpConfig.port}");
      }
    });
    manager.receiveStream.listen((Uint8List v) {
      // SrcID(0xee) DstID(0xee) length(0x00 0x00) Version(0x00) UserID(0x00) SAP(0x01) OptCode(0x85) Status(0x00) UserID(0x00)
      int sap = v[8];
      int optCode = v[9];
      int status = v[10];
      // 登录-回复
      if (sap == 0x01 && (optCode == 0x85 || optCode == 0x81)) {
        TimeoutManager.clearTimeout("login");
        if (status != 0x00 && status != 0x02) {
          udpPopError(t.udp.loginFail);
        } else {
          udpRadiosInfo.userId = v[11];
          // 1、读取路径下的压缩包的字节
          File injectFile = File(udpRadiosInfo.tarPath!);
          Uint8List bytes = injectFile.readAsBytesSync();
          // 2、要发送的 包头
          int packetCont = ByteTools.chunkBytes(bytes, chunkSize: 500).length;
          Uint8List packetHeader = ProtoManifest.fileHeader(
            // fileName: "/lib/fireware/plan_local.tar",
            fileName: "./plan_local.tar",
            // fileName: "plan_local.tar",
            fileSize: bytes.length,
            packetCnt: packetCont,
            userId: udpRadiosInfo.userId!,
          );
          udpRadiosInfo.packetHeader = packetHeader;
          // 3、分包
          List<Uint8List> packets = ProtoManifest.fileData(
            packetSize: 500,
            data: bytes,
            userId: udpRadiosInfo.userId,
          );
          udpRadiosInfo.packets = packets;
          // ping(); // 暂时不使用心跳
          fileHeader();
        }
      } else if (sap == 0x01 && optCode == 0x83) {
        TimeoutManager.clearTimeout("ping");
        if (status != 0) {
          udpPopError(t.udp.pingFail);
        } else {
          TimeoutManager.setTimeout(
            "ping",
            AppConfig.udpConfig.timeoutDuration,
            () {
              ping();
            },
          );
        }
      } else if (sap == 0x04 && optCode == 0x83) {
        if (status != 0) {
          udpPopError("包头传输失败");
        } else {
          filePacket();
        }
      } else if (sap == 0x04 && optCode == 0x84) {
        if (status != 0) {
          udpPopError(t.udp.fileFail);
        } else {
          filePacket();
        }
      }
    });
  }

  Future<void> login() async {
    TimeoutManager.clearAll();
    Uint8List bytes = ProtoManifest.loginWithPing("admin");
    manager.write(bytes, dtc.dialog.deviceIP.text);
    TimeoutManager.setTimeout("login", AppConfig.udpConfig.timeoutDuration, () {
      udpPopError(t.udp.loginTimeout);
    });
  }

  Future<void> ping() async {
    TimeoutManager.clearTimeout("ping");
    Uint8List bytes = ProtoManifest.ping(udpRadiosInfo.userId!);
    manager.write(bytes, dtc.dialog.deviceIP.text);
    TimeoutManager.setTimeout("ping", AppConfig.udpConfig.timeoutDuration, () {
      udpPopError(t.udp.pingTimeout);
    });
  }

  Future<void> fileHeader() async {
    manager.write(udpRadiosInfo.packetHeader, dtc.dialog.deviceIP.text);
    TimeoutManager.setTimeout(
      "fileHeader",
      AppConfig.udpConfig.timeoutDuration,
      () {
        udpPopError("包头传输超时");
      },
    );
  }

  Future<void> filePacket() async {
    if (TimeoutManager.hasTimer("fileHeader")) {
      TimeoutManager.clearTimeout("fileHeader");
    }
    TimeoutManager.clearTimeout("filePacket");
    if (udpRadiosInfo.packets.isNotEmpty) {
      manager.write(udpRadiosInfo.packets[0], dtc.dialog.deviceIP.text);
      udpRadiosInfo.packets.removeAt(0);
      TimeoutManager.setTimeout(
        "filePacket",
        AppConfig.udpConfig.timeoutDuration,
        () {
          udpPopError("文件传输超时");
        },
      );
    } else {
      udpPopSuccess(t.common.OperationSuccess);
    }
  }

  Future<void> udpPopError(String msg) async {
    SimplePopup.hideLoading();
    SimpleAsyncPopup.error(msg, timeout: Duration(milliseconds: 400));
  }

  Future<void> udpPopSuccess(String msg) async {
    SimplePopup.hideLoading();
    SimpleAsyncPopup.success(msg, timeout: Duration(milliseconds: 400));
  }
}
