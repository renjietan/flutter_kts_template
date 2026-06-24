import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/utils/files/FileSelector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../api/uploadFilesApi.dart';
import '../../utils/files/PermissionException.dart';
import 'fileUploads.dart';

mixin FileUploadsMixin on State<FileUploads> {
  final TextEditingController simpleTextController = TextEditingController();

  String path = "";
  late bool isUploadLoading = false;

  Future<void> pickFiles() async {
    setState(() {
      path = "";
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
      String response = await UploadFilesApi.single(file: file);
      if (response.isNotEmpty) {
        GlobalLogger.logInfo("response: $response");
        Pop.toast(t.uploads.success, toastType: ToastType.success);
        setState(() {
          path = file.path!;
          simpleTextController.text = file.path!;
          isUploadLoading = false;
        });
      } else {
        Pop.toast(t.uploads.failed, toastType: ToastType.error);
        setState(() {
          path = "";
          simpleTextController.text = "";
          isUploadLoading = false;
        });
      }
    } on PermissionException catch (e) {
      Pop.toast(e.toString(), toastType: ToastType.error);
      Future.delayed(Duration(milliseconds: 1500)).then((_) async {
        setState(() {
          simpleTextController.text = "";
          isUploadLoading = false;
        });
        Pop.confirm(
          title: t.common.confirm,
          content: t.permission.setting,
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
      });
    } catch (e) {
      Pop.toast(e.toString(), toastType: ToastType.error);
      setState(() {
        simpleTextController.text = "";
        isUploadLoading = false;
      });
    }
  }

  Future<void> parseFile() async {}
}
