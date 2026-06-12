import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> getUploadsDirectory() async {
  // 优先使用 Platform.script 获取脚本所在目录
  final appDocDir = await getApplicationDocumentsDirectory();
  final uploadsDir = Directory(path.join(appDocDir.path, 'uploads'));

  if (!await uploadsDir.exists()) {
    await uploadsDir.create(recursive: true);
  }
  return uploadsDir.path;
}
