import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      final statusCode = err.response?.statusCode;
      switch (statusCode) {
        case 401:
          // print('⚠️ Token 已过期，跳转登录');
          // // 示例：globalNavigatorKey.currentState?.pushNamed('/login');
          break;
        case 403:
          print('⚠️ 无权限访问');
          break;
        case 500:
          print('⚠️ 服务器内部错误');
          break;
        default:
          break;
      }
    }
    handler.next(err); // 这里抛出错误 给_
  }
}
