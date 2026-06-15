import 'package:flutter/material.dart';
import 'package:universal_file_picker/universal_file_picker.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  List<UFile> _selectedFiles = [];
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    final files = await UniversalFilePicker().pickFiles(
      options: PickOptions(allowMultiple: true, allowedExtensions: ["zip"]),
    );
    setState(() {
      _selectedFiles = files;
      _isUploading = false;
      _uploadFiles();
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);
    final uploader = UFileUploader();

    try {
      final results = await uploader.uploadFile(
        file: _selectedFiles[0],
        options: UploadOptions(
          url: 'http://localhost:8080/api/uploadServer/zip',
        ),
      );
      if (results.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('成功上传 ${results} 个文件'), backgroundColor: ThemeData.dark().primaryColor,));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('上传失败: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickFiles,
          icon: Icon(Icons.attach_file),
          label: Text('选择文件'),
        ),
      ],
    );
  }
}
