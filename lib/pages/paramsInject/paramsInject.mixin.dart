import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/api/KeyLoaders.api.dart';
import 'package:flutter_kts_template/components/DropDown/SimpleDarkDropdown/simple.dark.dropdown.item.dart';
import 'package:flutter_kts_template/components/TextField/simple.form.textfield.dart';
import 'package:flutter_kts_template/components/dialog/simple.tips.dialog.dart';
import 'package:flutter_kts_template/components/step/simple.number.step.model.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';
import 'package:flutter_kts_template/core/rtc/managers/socketIO/socket.io.manager.dart';
import 'package:flutter_kts_template/core/rtc/tools/proto/pManifest.dart';
import 'package:flutter_kts_template/core/rtc/tools/rtc.receive.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.model.dart';
import 'package:flutter_kts_template/pages/paramsInject/paramsInject.tools.dart';
import 'package:flutter_kts_template/utils/devicePermission/requestPermissions.dart';
import 'package:flutter_kts_template/utils/networkUtils/network.utils.dart';
import 'package:flutter_kts_template/utils/provider/menu.provider.dart';
import 'package:flutter_kts_template/utils/response/BaseListResponse.dart';
import 'package:flutter_kts_template/utils/response/BaseResponse.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:unified_popups/unified_popups.dart';

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

mixin ParamsInjectMixin<T extends StatefulWidget> on State<T> {
  Map<String, dynamic> allData = {};
  List<KeyLoadersEntity> keyLoaders = [];
  // 文件基础路径
  String dataPath = "";
  String get netNOdePath =>
      p.join(dataPath, "4_net_node", "${mtc.select.id}.json");
  String get dcJsonFolderPath => p.join(dataPath, "3_device_config");
  String get resourcePath => p.join(dataPath, "1_resource");
  List<String> get keyLoaderOptions =>
      keyLoaders.map((item) => item.name).toList();
  String get deviceAddress => "${dtc.dialog.deviceIP.text}:60009";

  MasterTreeConfig mtc = MasterTreeConfig(
    searchValue: "",
    visible: false,
    select: MasterTreeSelectConfig(id: "", type: -1, title: ""),
    searchTextFieldController: TextEditingController(),
    data: TreeType(
      data: SimpleTreeNode(id: "1", title: ""),
      children: [],
      parent: null,
    ),
  );
  String bindKeyLoaderId = "";
  List<SimpleNumberStepModel> steps = [];
  List<SimpleDarkDropdownItem<int>> networkOptions = [];
  List<String> foundDevice = [];

  DetailTreeConfig dtc = DetailTreeConfig(
    data: [],
    visible: false,
    treeVisible: false,
    dialog: DetailTreeDialogConfig(
      deviceType: TextEditingController(),
      deviceIP: TextEditingController(),
    ),
    selectRows: {},
    activeStep: 1,
    selectWifi: -1,
    socketIOManager: null,
  );

  late UdpManager manager;
  late DeviceFileModel deviceFileModel = DeviceFileModel(
    packets: [],
    packetHeader: Uint8List.fromList([]),
    userId: null,
    tarPath: "",
  );

  void resetMasterTree() {
    mtc.searchValue = "";
    mtc.visible = false;
    mtc.select = MasterTreeSelectConfig(id: "", type: -1, title: "");
    mtc.searchTextFieldController.text = "";
    mtc.data = TreeType(
      data: SimpleTreeNode(id: "1", title: ""),
      children: [],
      parent: null,
    );
    resetDetailTree();
  }

  void resetDetailTree() {
    dtc.data = [];
    dtc.visible = false;
    dtc.treeVisible = false;
    dtc.selectRows.clear();
    dtc.activeStep = 1;
    dtc.selectWifi = -1;
    dtc.socketIOManager?.disconnect();
    dtc.socketIOManager = null;
    setState(() {});
  }

  void initSteps(BuildContext ctx) {
    final t = Translations.of(ctx);
    setState(() {
      steps = [
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.discovery,
          isActive: true,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.authentication,
          isActive: false,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.transfer,
          isActive: false,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.parse,
          isActive: false,
        ),
        SimpleNumberStepModel(
          label: t.pager.injectParams.steps.finish,
          isActive: false,
        ),
      ];
    });
  }

  Future<void> detailRefresh() async {
    dtc.data = [];
    await initNetworkInterfaceOptions();
    foundDevice = [];
    dtc.selectWifi = -1;
    dtc.activeStep = 1;
    dtc.selectRows = {};
    setState(() {});
  }

  Future<void> initNetworkInterfaceOptions() async {
    var a = await NetworkUtil.getIPv4LANInterfaces();
    networkOptions = [];
    for (var i = 0; i < a.length; i++) {
      SimpleDarkDropdownItem<int> temp = SimpleDarkDropdownItem(
        value: i,
        label: "${a[i].interfaceName}-${a[i].ip}",
      );
      networkOptions.add(temp);
    }
  }

  Future<void> initLeftTree(String? filePath) async {
    setState(() {
      mtc.visible = false;
    });
    bool hasPermission = await RequestPermission.requestStoragePermission();
    if (!hasPermission) {
      Pop.toast(t.permission.cancel, toastType: ToastType.warn);
      return;
    }
    initMasterTree(filePath);
  }

  Future<void> initMasterTree(String? filePath) async {
    final (data, path) = await readAllDataFiles(filePath);
    allData = data;
    dataPath = path;
    if (allData.isEmpty) {
      setState(() {
        mtc.visible = true;
      });
      return;
    }
    Map<String, dynamic> contacts = allData["0_contacts"] ?? {};
    for (var key in contacts.keys) {
      Map<String, dynamic> unitTree = contacts[key]["UnitTree"] ?? {};

      if (unitTree.isEmpty) continue;
      Map<String, dynamic> temp = transformUnitTree(
        unitTree,
        fullData: allData,
      );

      setState(() {
        final (data, _) = buildTree(temp, activeSelection: true);
        mtc.data = data;
        mtc.visible = true;
      });
    }
  }

  Future<void> masterTreeOnSelect(
    BuildContext ctx,
    TreeType<SimpleTreeNode> v,
  ) async {
    resetDetailTree();
    initNetworkInterfaceOptions();
    initSteps(ctx);
    var id = v.data.id;
    if (mtc.select.id == id) {
      return;
    }
    mtc.select.id = id;
    mtc.select.type = v.data.type ?? 999;
    mtc.select.title = v.data.title;
    setState(() {});
    foundDevice = ["0"];
    initDetailTree();
  }

  void initDetailTree() {
    setState(() {
      dtc.visible = false;
    });
    Map<String, dynamic> netNodes = allData["4_net_node"][mtc.select.id] ?? {};
    Map<String, dynamic> netNodesSystemConfig =
        netNodes["SystemConfiguration"] ?? {};
    Map<String, dynamic> members = netNodesSystemConfig["LANMember"] ?? {};
    Map<String, dynamic> primaries = netNodesSystemConfig["LANPrimary"] ?? {};
    Map<String, dynamic> radios = netNodesSystemConfig["Radio"] ?? {};
    List<String> ccus = [
      ...(members["CCU"] ?? []),
      ...(primaries["CCU"] ?? []),
      ...(radios["CCU"] ?? []),
    ];
    List<String> servers = [
      ...(members["Server"] ?? []),
      ...(primaries["Server"] ?? []),
      ...(radios["Server"] ?? []),
    ];
    if (ccus.isNotEmpty && mtc.select.type != 1) {
      Map<String, dynamic> ccuNodes = parseCcuAndServerNodes(
        ccus,
        rootTitle: "CCU",
      );
      final (ccuTree, _) = buildTree(
        ccuNodes,
        leafActionWidgetLabel: null,
        leafActionWidgetOnPressed: null,
        leafActionWidgetSize: null,
        startIndex: 0,
      );
      dtc.data.add(ccuTree);
    }
    if (servers.isNotEmpty && mtc.select.type != 1) {
      Map<String, dynamic> serversNodes = parseCcuAndServerNodes(
        servers,
        rootTitle: "Server",
      );
      final (serverTree, _) = buildTree(
        serversNodes,
        leafActionWidgetLabel: null,
        leafActionWidgetOnPressed: null,
        leafActionWidgetSize: null,
        startIndex: 0,
      );
      dtc.data.add(serverTree);
    }
    if (radios.keys.isNotEmpty) {
      radios = parseRadioNodes(
        radios,
        rootTitle: "Radio",
        type: mtc.select.type,
      );
      final (radioTree, _) = buildTree(
        radios,
        // 由于未来战士是多选 不显示 inject 按钮
        leafActionWidgetLabel: null,
        leafActionWidgetOnPressed: null,
        leafActionWidgetSize: null,
        startIndex: 0,
      );
      dtc.data.add(radioTree);
    }
    Future.delayed(Duration(milliseconds: 500)).then((_) {
      setState(() {
        dtc.visible = true;
      });
    });
  }

  Map<String, dynamic> parseCcuAndServerNodes(
    List<String> nodes, {
    required String rootTitle,
  }) {
    Map<String, dynamic> root = {
      "id": 0,
      "title": rootTitle,
      "NetNodes": [],
      "UserIds": [],
      "children": [],
      "isleaf": false,
      "isShowCheckbox": false,
      "type": 999,
    };
    root["children"] = nodes.fold([], (cur, pre) {
      String path = p.join(dcJsonFolderPath, "$pre.json");
      var res = FileTools.readFileContentAsMap(path);
      String ip =
          (res['audioBoardIpConfig']?['result']?['ip'] ?? res['Ipv4Subnet']) ??
          '';
      Map<String, dynamic> temp = {
        "id": 0,
        "title": pre,
        "NetNodes": [],
        "UserIds": [],
        "children": [],
        "isleaf": true,
        "isShowCheckbox": false,
        "type": 999,
        "subTexts": ["ESN: ", "当前IP: $ip"],
        "isActive": foundDevice[0] == "1",
        "activeTexts": foundDevice.isNotEmpty ? ["未连接", "已连接"] : null,
      };
      cur.add(temp);
      return cur;
    });
    return root;
  }

  Map<String, dynamic> parseRadioNodes(
    Map<String, dynamic> nodes, {
    required String rootTitle,
    required int type,
  }) {
    Map<String, dynamic> root = {
      "id": 0,
      "title": rootTitle,
      "NetNodes": [],
      "UserIds": [],
      "children": [],
      "isleaf": false,
      "isShowCheckbox": false,
      "type": 999,
    };
    int id = DateTime.now().millisecondsSinceEpoch;
    nodes.forEach((key, value) {
      id++;
      Map<String, dynamic> sonNode = {
        "id": "key-$id",
        "title": key,
        "NetNodes": [],
        "UserIds": [],
        "children": [],
        "isleaf": false,
        "isShowCheckbox": false,
        "type": 999,
      };
      value.forEach((item) {
        id++;
        String path = p.join(dcJsonFolderPath, "$item.json");
        var res = FileTools.readFileContentAsMap(path);
        String ip = res["IP"] ?? '';
        sonNode["children"].add({
          "id": "key-$id",
          "title": item,
          "NetNodes": [],
          "UserIds": [],
          "children": [],
          "isleaf": true,
          "isShowCheckbox": type == 1,
          "type": 999,
          "subTexts": ["ESN: ", "当前ip: $ip"],
          "isActive": foundDevice[0] == "1" && type != 1,
          "activeTexts": foundDevice.isNotEmpty && type != 1
              ? ["未连接", "已连接"]
              : null,
        });
      });
      root["children"].add(sonNode);
    });
    return root;
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
            FormBuilderValidators.ip(
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

  Future<void> saveTo(BuildContext ctx) async {
    if (dtc.selectRows.keys.isEmpty) {
      SimplePopup.warn(t.tips.paramsInject.selectRadios);
      return;
    }
    SimplePopup.loading();
    try {
      BaseResponse<BaseListResponse<KeyLoadersEntity>> keyLoadersResponse =
          await KeyLoadersApi.getAll();
      keyLoaders = keyLoadersResponse.data.list;
      // SimplePopup.hideLoading();
      await SimpleAsyncPopup.hideLoading(Duration(milliseconds: 400));
      if (keyLoaders.isEmpty) {
        SimpleTipsDialog(
          ctx,
          title: t.tips.title,
          contentText: t.tips.paramsInject.noKeyLoader,
          func: () {
            Provider.of<MenuProvider>(ctx, listen: false).selectedIndex = 2;
            ctx.go("injectEncryptStick");
          },
        );
      } else {
        bindKeyLoaderId = "${keyLoaders[0].id}";
        SimpleFormDialog(
          title: t.button.paramsInject.bind,
          confirmText: t.button.paramsInject.bind,
          fields: [
            FormFieldConfig(
              name: 'keyLoader',
              items: keyLoaders,
              initialValue: keyLoaders[0],
              fieldType: FormFieldType.select,
              labelBuilder: (v) => v.name,
              label: t.Form.paramsInject.selectKeyLoader.text,
              hintText: t.Form.paramsInject.selectKeyLoader.placeholder,
              validators: [
                FormBuilderValidators.required(errorText: t.TextField.select),
              ],
              onChanged: (v) {
                bindKeyLoaderId = "${v.id}";
              },
            ),
          ],
          onConfirm: (v) {
            Map<String, dynamic> params = {
              "id": bindKeyLoaderId,
              "netNodePackageName": mtc.select.id,
              "dcPackageNames": dtc.selectRows.keys.join(","),
              "consumer": mtc.select.title,
            };
            KeyLoadersApi.updateDetail(bindKeyLoaderId, data: params).then((
              res,
            ) {
              SimplePopup.success(t.common.OperationSuccess);
            });
          },
        );
      }
    } catch (e) {
      SimplePopup.hideLoading();
    }
  }

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
      } else if (v.title.startsWith("dc_server_")) {
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
      deviceFileModel.tarPath = resPath;
      // var temp_test = ByteTools.str2UintList("./plan_local.tar");
      // print("===========================================");
      // print(ByteTools.uIntList2uIntListStr(temp_test));
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
    await manager.init(AppConfig.udpConfig.toString());
    manager.eventStream.listen((RtcEvent v) {
      if (v.type == RtcEventType.closed) {
        SimplePopup.error(t.udp.closed);
      } else if (v.type == RtcEventType.created) {
        GlobalLogger.logInfo("Udp start :${AppConfig.udpConfig.port}");
      }
    });
    manager.receiveStream.listen((RtcReceive data) {
      Uint8List v = data.data;
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
          deviceFileModel.userId = v[11];
          // 只能在登录成功后，开始 分包，因为需要userId
          readTarPackage();
          ping();
        }
      } else if (sap == 0x01 && optCode == 0x83) {
        if (TimeoutManager.hasTimer("login")) {
          TimeoutManager.clearTimeout("login");
        }
        TimeoutManager.clearTimeout("ping");
        if (status != 0) {
          udpPopError(t.udp.pingFail);
        } else {
          fileHeader();
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

  Future<void> initSocket() async {
    dtc.socketIOManager = SocketIOManager();
    if (dtc.socketIOManager?.isConnected ?? false) {
      dtc.socketIOManager!.init("");
      dtc.socketIOManager!.eventStream.listen((RtcEvent e) {
        print("socketmanager:" + e.toString());
      });
      dtc.socketIOManager!.receiveStream.listen((e) {
        print("socketmanager:" + e.toString());
      });
    }
  }

  void readTarPackage() {
    // 1、读取路径下的压缩包的字节
    File injectFile = File(deviceFileModel.tarPath!);
    Uint8List bytes = injectFile.readAsBytesSync();
    // 2、要发送的 包头
    int packetCont = ByteTools.chunkBytes(bytes, chunkSize: 500).length;
    String filename = "";
    if (dtc.dialog.deviceType.text == "ccu") {
      filename = "/home/update/plan_local.tar";
    } else if (dtc.dialog.deviceType.text == "server") {
      filename = "plan_local.tar";
    } else {
      filename = "plan_local.tar";
    }
    Uint8List packetHeader = ProtoManifest.fileHeader(
      fileName: filename,
      fileSize: bytes.length,
      packetCnt: packetCont,
      userId: deviceFileModel.userId!,
    );
    deviceFileModel.packetHeader = packetHeader;
    // 3、分包
    List<Uint8List> packets = ProtoManifest.fileData(
      packetSize: 500,
      data: bytes,
      userId: deviceFileModel.userId,
    );
    deviceFileModel.packets = packets;
  }

  Future<void> login() async {
    TimeoutManager.clearAll();
    Uint8List bytes = ProtoManifest.loginWithPing("admin");
    manager.write(bytes, deviceAddress);
    TimeoutManager.setTimeout("login", AppConfig.udpConfig.timeoutDuration, () {
      udpPopError(t.udp.loginTimeout);
    });
  }

  Future<void> ping() async {
    TimeoutManager.clearTimeout("ping");
    Uint8List bytes = ProtoManifest.ping(deviceFileModel.userId!);
    manager.write(bytes, deviceAddress);
    TimeoutManager.setTimeout("ping", AppConfig.udpConfig.timeoutDuration, () {
      udpPopError(t.udp.pingTimeout);
    });
  }

  Future<void> fileHeader() async {
    manager.write(deviceFileModel.packetHeader, deviceAddress);
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
    if (deviceFileModel.packets.isNotEmpty) {
      manager.write(deviceFileModel.packets[0], deviceAddress);
      deviceFileModel.packets.removeAt(0);
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
