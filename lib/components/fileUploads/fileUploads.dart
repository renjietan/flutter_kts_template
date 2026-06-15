import 'package:flutter/material.dart';
import 'package:universal_file_picker/universal_file_picker.dart';

class FilePickerScreen extends StatefulWidget {
  @override
  _FilePickerScreenState createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  List<UFile> _selectedFiles = [];
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    final files = await UniversalFilePicker().pickFiles(
      options: PickOptions(allowMultiple: true, allowedExtensions: ["zip"]),
    );
    _uploadFiles();
    setState(() {
      _selectedFiles = files;
      _uploadProgress = 0.0;
      _isUploading = false;
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);
    final uploader = UFileUploader();

    try {
      final results = await uploader.uploadBatchWithProgress(
        files: _selectedFiles,
        options: UploadOptions(
          url: 'localhost:8080/api/uploadServer/zip',
          // fields: {'userId': '123'},
        ),
        onProgress: (current, total, progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('成功上传 ${results.length} 个文件')));
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
        // if (_selectedFiles.isNotEmpty) ...[
        //   Expanded(
        //     child: ListView.builder(
        //       itemCount: _selectedFiles.length,
        //       itemBuilder: (context, index) {
        //         final file = _selectedFiles[index];
        //         return ListTile(
        //           leading: Icon(Icons.insert_drive_file),
        //           title: Text(file.name),
        //           subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB'),
        //         );
        //       },
        //     ),
        //   ),
        //   if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
        //   ElevatedButton(
        //     onPressed: _isUploading ? null : _uploadFiles,
        //     child: Text(
        //       _isUploading
        //           ? '上传中 (${(_uploadProgress * 100).toStringAsFixed(0)}%)'
        //           : '上传',
        //     ),
        //   ),
        // ],
      ],
    );
  }
}
