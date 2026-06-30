import 'package:flutter_kts_template/core/entities/radios/radiosEntity.dart';
import 'package:flutter_kts_template/utils/response/BaseListResponse.dart';

import '../utils/request/httpClient.dart';

class RadiosManagerApi {
  static final DioClient _instance = DioClient();
  static final String url = "/radiosManager";

  static Future getList({
    required String page,
    required String pageSize,
    required String keyword,
  }) async {
    final res = await _instance.get(
      url,
      queryParameters: {"page": page, "pageSize": pageSize, "keyword": keyword},
      fromJson: (json) => BaseListResponse.fromJson(
        json as Map<String, dynamic>,
        (item) => RadiosEntity.fromJson(item),
      ),
    );
    return res;
  }

  static Future create(Map<String, dynamic> data) async {
    final res = await _instance.post(url, data: data, fromJson: null);
    return res;
  }

  static Future update(int id, {required Map<String, dynamic> data}) async {
    final res = await _instance.put("$url/$id", data: data, fromJson: null);
    return res;
  }

  static Future delete(String id) async {
    final res = await _instance.delete("$url/$id", fromJson: null);
    return res;
  }
}
