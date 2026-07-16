import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';

import '../utils/request/httpClient.dart';
import '../utils/response/BaseListResponse.dart';

class BindConfigApi {
  static final DioClient _instance = DioClient();
  static final String url = "/bindConfig";

  static Future getAll() async {
    final res = await _instance.get(
      url,
      fromJson: (json) => BaseListResponse.fromJson(
        json as Map<String, dynamic>,
        (item) => KeyLoadersEntity.fromJson(item),
      ),
    );
    return res;
  }

  static Future create(Map<String, dynamic> data) async {
    final res = await _instance.post(url, data: data, fromJson: null);
    return res;
  }
}
