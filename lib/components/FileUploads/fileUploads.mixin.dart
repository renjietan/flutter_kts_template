import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/logger/logger.dart';
import 'package:flutter_kts_template/utils/files/FileSelector.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../api/uploadFilesApi.dart';
import 'fileUploads.dart';

mixin FileUploadsMixin on State<FileUploads> {
  final TextEditingController simpleTextController = TextEditingController();

  late bool isUploadLoading = false;

  Future<void> pickFiles(BuildContext ctx) async {
    setState(() {
      isUploadLoading = true;
    });
    _uploadFiles(ctx);
  }

  Future<void> _uploadFiles(BuildContext ctx) async {
    PlatformFile? file = await FileSelector.pickFile(null);
    if (file == null) {
      setState(() {
        isUploadLoading = false;
      });
      Pop.toast('已取消', toastType: ToastType.warn);
      return;
    }
    try {
      String response = await UploadFilesApi.single(file: file);
      if (response.isNotEmpty) {
        GlobalLogger.logInfo("response: $response");
        Pop.toast('文件已上传', toastType: ToastType.success);
        setState(() {
          simpleTextController.text = file.path!;
          isUploadLoading = false;
        });
      } else {
        Pop.toast('文件上传失败', toastType: ToastType.error);
        setState(() {
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
}
