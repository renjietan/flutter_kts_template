import '../core/entities/radios/radiosEntity.dart';
import '../utils/request/httpClient.dart';
import '../utils/response/BaseListResponse.dart';

class RadiosManagerApi {
  static final DioClient _instance = DioClient();
  static final String url = "/radiosManager";

  static Future<BaseListResponse<RadiosEntity>> getList({
    required String page,
    required String pageSize,
    required String keyword,
  }) async {
    Map<String, dynamic> resJson = await _instance.get<Map<String, dynamic>>(
      url,
      queryParameters: {"page": page, "pageSize": pageSize, "keyword": keyword},
    );
    BaseListResponse<RadiosEntity> res = BaseListResponse.fromJson(
      resJson,
      (item) => RadiosEntity.fromJson(item),
    );
    return res;
  }

  static Future<dynamic> create(Map<String, dynamic> data) async {
    Map<String, dynamic> res = await _instance.post<Map<String, dynamic>>(
      url,
      data: data,
    );
    // BaseListResponse<RadiosEntity> res = BaseListResponse.fromJson(
    //   resJson,
    //   (item) => RadiosEntity.fromJson(item),
    // );
    return res;
  }
}
