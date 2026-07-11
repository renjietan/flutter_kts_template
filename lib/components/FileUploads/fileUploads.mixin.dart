import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/utils/files/FileTools.dart';
import 'package:flutter_kts_template/utils/files/exception/FileException.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../core/utils/common.dart';
import '../../core/utils/director.dart';
import '../../core/utils/time.dart';
import '../../utils/files/exception/PermissionException.dart';
import '../../utils/files/pick_files/FileSelector.dart';
import 'fileUploads.dart';

mixin FileUploadsMixin on State<FileUploads> {
  final TextEditingController simpleTextController = TextEditingController();

  String remoteFilePath = "";
  late bool isUploadLoading = false;

  Future<void> pickFiles() async {
    setState(() {
      remoteFilePath = "";
      isUploadLoading = true;
      simpleTextController.text = "";
    });
    _uploadFiles();
  }

  Future<void> _uploadFiles() async {
    try {
      PlatformFile? file = await FileSelector.pickFile(null);
      if (file == null) {
        setState(() {
          isUploadLoading = false;
        });
        Pop.toast(t.uploads.cancel, toastType: ToastType.warn);
        return;
      }
      // 逻辑修改，不调用接口
      var bytes = file.bytes;
      if (bytes != null) {
        String uploadPath = await DirectoryManager.instance.getUploadsPath();
        String safeFileName = sanitizeFileName(file.name);
        String curTime = parseDateTime(DateTime.now());
        curTime = curTime.replaceAll(':', '-');
        final saveFilePath = path.join(uploadPath, "[$curTime] $safeFileName");
        final fileObject = File(saveFilePath);
        await fileObject.writeAsBytes(bytes);
        GlobalLogger.logInfo(saveFilePath);
        Pop.toast(
          t.uploads.successWithPath(path: saveFilePath),
          toastType: ToastType.success,
        );
        setState(() {
          remoteFilePath = saveFilePath;
          simpleTextController.text = file.path!;
          isUploadLoading = false;
        });
      } else {
        Pop.toast(t.uploads.failed, toastType: ToastType.error);
        setState(() {
          remoteFilePath = "";
          simpleTextController.text = "";
          isUploadLoading = false;
        });
      }
      // BaseResponse<dynamic> response = await UploadFilesApi.single(file: file);
      // if (response.data is String) {
      //   Pop.toast(
      //     t.uploads.successWithPath(path: response),
      //     toastType: ToastType.success,
      //   );
      //   setState(() {
      //     remoteFilePath = response.data;
      //     simpleTextController.text = file.path!;
      //     isUploadLoading = false;
      //   });
      // } else {
      //   Pop.toast(t.uploads.failed, toastType: ToastType.error);
      //   setState(() {
      //     remoteFilePath = "";
      //     simpleTextController.text = "";
      //     isUploadLoading = false;
      //   });
      // }
    } on PermissionException catch (e) {
      Pop.toast(e.toString(), toastType: ToastType.error);
      setState(() {
        simpleTextController.text = "";
        isUploadLoading = false;
      });
      Pop.confirm(
        title: t.common.confirm,
        content: t.permission.no,
        confirmText: t.common.confirm,
        cancelText: t.common.cancel,
        onConfirm: () async {
          bool r = await openAppSettings();
          GlobalLogger.logInfo(r.toString());
        },
        onCancel: () async {
          Pop.toast(t.permission.cancel, toastType: ToastType.warn);
        },
      );
    } catch (e) {
      Pop.toast(e.toString(), toastType: ToastType.error);
      setState(() {
        simpleTextController.text = "";
        isUploadLoading = false;
      });
    }
  }

  Future<void> parseFile() async {
    setState(() {
      isUploadLoading = true;
    });
    String? outPath;
    try {
      if (remoteFilePath.isEmpty) {
        outPath = await FileSelector.pickFolder();
        if (outPath == null) {
          setState(() {
            isUploadLoading = false;
          });
          SimplePopup.warn(t.uploads.cancel);
          return;
        }
        remoteFilePath = outPath;
        simpleTextController.text = outPath;
      }
      var archiveExt = getInputExtension(remoteFilePath);
      if (archiveExt == ".zip") {
        outPath = remoteFilePath.split(archiveExt)[0];
        await extractFileToDisk(remoteFilePath, outPath);
      } else if (archiveExt == "") {
        outPath = remoteFilePath;
      } else {
        SimplePopup.error(t.uploads.selectedAllow);
        return;
      }
      widget.onUpdate.call(outPath);
      // await parseData(outPath);
      setState(() {
        isUploadLoading = false;
      });
    } on FileException catch (e) {
      setState(() {
        isUploadLoading = false;
      });
      SimplePopup.error(e.toString());
    } catch (e) {
      setState(() {
        isUploadLoading = false;
      });
      SimplePopup.error(e.toString());
    }
  }
}

Future<Map<String, dynamic>> parseData(String filePath) async {
  List<Directory> subFolders = await FileTools.getDirectSubFolders(filePath);
  List<Future<Map<String, dynamic>>> futures = subFolders
      .map((item) => FileTools.readAllJsonFiles(item))
      .toList();
  return await Future.wait(futures).then((res) {
    var temp = res.fold(
      {
        "key": <String, dynamic>{},
        "radio_subnet": <String, dynamic>{},
        "device_config": <String, dynamic>{},
        "net_node": <String, dynamic>{},
        "users": <String, dynamic>{},
        "contacts": <String, dynamic>{},
      },
      (cur, pre) {
        if (pre.isEmpty) {
          return cur;
        }
        List<String> keys = pre.keys.toList();
        if (keys.every((item) => item.indexOf("rs_") == 0)) {
          cur["radio_subnet"] = pre;
        } else if (keys.every((item) => item.indexOf("dc_") == 0)) {
          cur["device_config"] = pre;
        } else if (keys.every((item) => item.indexOf("nn_") == 0)) {
          cur["net_node"] = pre;
        } else if (keys.every((item) => item.indexOf("user_") == 0)) {
          cur["users"] = pre;
        } else if (keys.every((item) => item.indexOf("contacts_") == 0)) {
          cur["contacts"] = pre;
        } else {
          Map<String, dynamic> data = parseKeys(pre);
          cur["key"] = data;
        }
        return cur;
      },
    );
    // EncryptConfigEntity ee = EncryptConfigEntity.fromJson(temp);
    return temp;
  });
}

Map<String, dynamic> parseKeys(Map<String, dynamic> data) {
  Map<String, dynamic> res = {};
  data.forEach((key, value) {
    Map<String, dynamic> temp = {};
    temp["File"] = value["File"];
    Map<String, String> keys = {};
    value.forEach((k, v) {
      int? r = int.tryParse(k as String);
      if (r != null) {
        keys[k] = v;
      }
    });
    temp["keys"] = keys;
    res[key] = temp;
  });
  return res;
}

/// 递归转换节点树
/// 输入：包含 'Unit', 'NetNodes', 'SubUnits' 的节点 Map
/// 输出：包含 'id', 'title', 'NetNodes', 'chldren' 的新 Map
Map<String, dynamic> transformUnitTree(
  Map<String, dynamic> node, {
  required bool fillNode,
}) {
  var unit = node['Unit'] as Map<String, dynamic>;

  // 构建新节点
  final result = <String, dynamic>{
    'id': unit['UnitId'],
    'title': unit['CodeName'],
    "isleaf": unit["isleaf"] ?? false,
    "type": unit["NodeType"] ?? -1,
    "users": unit["Users"] ?? [],
  };

  // 递归处理子单位
  var subUnits = (node['SubUnits'] as List? ?? []);
  final netNodes = node['NetNodes'] as List? ?? [];
  final newNetNodes = netNodes.map((n) => transformNetNode(n)).toList();
  subUnits = [...newNetNodes, ...subUnits];
  if (!result["isleaf"] && subUnits.isEmpty && fillNode) {
    int randomNum = DateTime.now().millisecond;
    subUnits = [
      {
        "Unit": {
          "UnitId": randomNum + 1,
          "CodeName": t.tree.empty,
          "isleaf": true,
        },
      },
    ];
  }
  result['children'] = subUnits
      .map((child) => transformUnitTree(child, fillNode: fillNode))
      .toList();
  return result;
}

Map<String, dynamic> transformNetNode(Map<String, dynamic> netNode) {
  final result = Map<String, dynamic>.from(netNode);
  result["Unit"] = <String, dynamic>{};
  result["Unit"]['UnitId'] = result.remove('NodeId');
  result["Unit"]['CodeName'] = result.remove('CodeName');
  result["Unit"]["isleaf"] = true;
  result["Unit"]["NodeType"] = result.remove('NodeType');
  result["Unit"]["Users"] = result.remove('Users');
  result["NetNodes"] = [];
  result["SubUnits"] = [];
  return result;
}
