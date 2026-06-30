import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/utils/files/FileTools.dart';
import 'package:flutter_kts_template/utils/files/exception/FileException.dart';
import 'package:flutter_kts_template/utils/response/BaseResponse.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../api/uploadFilesApi.dart';
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
      BaseResponse<dynamic> response = await UploadFilesApi.single(file: file);
      if (response.data is String) {
        // String successMsg = t.uploads.success(path: response);
        Pop.toast(
          t.uploads.successWithPath(path: response),
          toastType: ToastType.success,
        );
        setState(() {
          remoteFilePath = response.data;
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
    if (remoteFilePath.isEmpty) {
      Pop.toast(t.uploads.emptyPath, toastType: ToastType.error);
      return;
    }
    try {
      var archiveExt = getInputExtension(remoteFilePath);
      String outPath = remoteFilePath.split(archiveExt)[0];
      await extractFileToDisk(remoteFilePath, outPath);
      List<Directory> subFolders = await FileTools.getDirectSubFolders(outPath);
      List<Future<Map<String, dynamic>>> futures = subFolders
          .map((item) => FileTools.readAllJsonFiles(item))
          .toList();
      await Future.wait(futures).then((res) {
        print(res);
      });
    } on FileException catch (e) {
      Pop.toast(e.toString(), toastType: ToastType.error);
    } catch (e) {
      Pop.toast(e.toString(), toastType: ToastType.error);
    }
  }
}
