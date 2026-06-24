import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/utils/files/FileSelector.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../api/uploadFilesApi.dart';
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
    PlatformFile? file = await FileSelector.pickFile(null);
    if (file == null) {
      setState(() {
        isUploadLoading = false;
      });
      Pop.toast(t.uploads.cancel, toastType: ToastType.warn);
      return;
    }
    try {
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
