import 'dart:io';

import '../../components/FileUploads/fileUploads.mixin.dart';
import '../../core/utils/director.dart';
import '../../utils/files/FileTools.dart';

/// [directoryPath] 获取文件夹下 所有文本内容
///
/// 返回 Map，键为文件名，值为解析后的 JSON 对象（Map 或 List）。
Future<(Map<String, dynamic>, String)> readAllDataFiles(
  String? filePath,
) async {
  if (filePath != null && filePath.isNotEmpty) {
    var res = await parseData(filePath);
    return (res, filePath);
  }
  String defaultUploadPath = await DirectoryManager.instance.getUploadsPath();
  List<Directory> subFolders = await FileTools.getDirectSubFolders(
    defaultUploadPath,
  );
  if (subFolders.isEmpty) return (<String, dynamic>{}, "");
  subFolders.sort((a, b) {
    DateTime timeA = a.statSync().changed;
    DateTime timeB = b.statSync().changed;
    return timeB.compareTo(timeA);
  });
  var res = await parseData(subFolders[0].path);
  return (res, subFolders[0].path);
}
