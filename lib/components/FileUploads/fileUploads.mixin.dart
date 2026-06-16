import 'package:flutter/material.dart';
import 'package:unified_popups/unified_popups.dart';
import 'package:universal_file_picker/universal_file_picker.dart';

import 'fileUploads.dart';

mixin FileUploadsMixin on State<FileUploads> {
  late String filePath = "";
  late bool isUploadLoading = false;
  List<UFile> _selectedFiles = [];

  Future<void> pickFiles() async {
    final files = await UniversalFilePicker().pickFiles(
      options: PickOptions(allowMultiple: true, allowedExtensions: ["zip"]),
    );
    setState(() {
      _selectedFiles = files;
      isUploadLoading = false;
      filePath = files.isNotEmpty ? files[0].path! : "";
      _uploadFiles();
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => isUploadLoading = true);
    final uploader = UFileUploader();

    try {
      final result = await uploader.uploadFile(
        file: _selectedFiles[0],
        options: UploadOptions(
          url: 'http://localhost:8080/api/uploadServer/zip',
        ),
      );
      if (result.success) {
        Pop.toast('文件已上传', toastType: ToastType.success);
      }
    } catch (e) {
      return;
    } finally {
      setState(() => isUploadLoading = false);
    }
    return;
  }
}
