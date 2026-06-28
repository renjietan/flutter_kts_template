import '../utils/request/httpClient.dart';

class RadiosManagerApi {
  static final DioClient _instance = DioClient();
  static final String url = "/radiosManager";

  static Future<Map<String, dynamic>> getList() async {
    Map<String, dynamic> res = await _instance.get<Map<String, dynamic>>(
      url,
      queryParameters: {"page": "1", "pageSize": "10"},
      // parser: (dynamic data) {
      //   if (data == null) return <RadiosEntity>[];
      //   // 确保 data 是 List 类型
      //   if (data is! List) return <RadiosEntity>[];
      //   // 将每个元素转为 Map（如果可能），否则跳过
      //   return data
      //       .whereType<Map<String, dynamic>>() // 只保留 Map 类型元素
      //       .map((e) => RadiosEntity.fromJson(e))
      //       .toList();
      // },
    );
    return res;
  }
}
