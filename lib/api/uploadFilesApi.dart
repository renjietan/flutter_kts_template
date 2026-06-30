import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/utils/request/httpClient.dart';
import 'package:flutter_kts_template/utils/response/BaseResponse.dart';

class UploadFilesApi {
  static final DioClient _instance = DioClient();
  static final String pre = "/uploadServer";

  // 上传单个文件（任意类型）
  static Future<BaseResponse<dynamic>> single({
    String url = "/zip",
    required PlatformFile file,
    Map<String, dynamic>? extraFields,
    void Function(int count, int total)? onProgress,
  }) async {
    FormData formData = FormData();
    if (kIsWeb) {
      // Web 平台：使用 bytes
      if (file.bytes == null) {
        throw Exception(t.uploads.emptyData);
      }
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(file.bytes!, filename: file.name),
        ),
      );
    } else {
      // 移动端/桌面端：使用文件路径
      if (file.path == null) {
        throw Exception(t.uploads.emptyPath);
      }
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(file.path!, filename: file.name),
        ),
      );
    }

    // 添加额外表单字段
    if (extraFields != null) {
      extraFields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    var res = await _instance.post(pre + url, data: formData, fromJson: null);
    return res;
  }
}
