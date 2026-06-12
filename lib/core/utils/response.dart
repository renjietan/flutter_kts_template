import 'dart:convert';

import 'package:shelf/shelf.dart';

/// 统一的 API 响应格式
class ApiResponse {
  /// 状态码（业务状态码，非 HTTP 状态码）
  final int code;
  /// 提示消息
  final String message;
  /// 返回的数据（可以是任意类型，最终会被转为 JSON）
  final dynamic data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  /// 成功响应 (HTTP 200)
  static Response success({dynamic data, String message = 'success'}) {
    return _response(
      code: 200,
      message: message,
      data: data,
      httpStatus: 200,
    );
  }

  /// 失败响应（客户端错误，HTTP 400）
  static Response error({
    String message = 'error',
    dynamic data,
    int code = 400,
    int httpStatus = 400,
  }) {
    return _response(
      code: code,
      message: message,
      data: data,
      httpStatus: httpStatus,
    );
  }

  /// 未授权 (HTTP 401)
  static Response unauthorized({String message = 'unauthorized', dynamic data}) {
    return _response(
      code: 401,
      message: message,
      data: data,
      httpStatus: 401,
    );
  }

  /// 禁止访问 (HTTP 403)
  static Response forbidden({String message = 'forbidden', dynamic data}) {
    return _response(
      code: 403,
      message: message,
      data: data,
      httpStatus: 403,
    );
  }

  /// 资源不存在 (HTTP 404)
  static Response notFound({String message = 'not found', dynamic data}) {
    return _response(
      code: 404,
      message: message,
      data: data,
      httpStatus: 404,
    );
  }

  /// 服务器内部错误 (HTTP 500)
  static Response internalError({String message = 'internal server error', dynamic data}) {
    return _response(
      code: 500,
      message: message,
      data: data,
      httpStatus: 500,
    );
  }

  static Response _response({
    required int code,
    required String message,
    dynamic data,
    required int httpStatus,
  }) {
    final body = jsonEncode({
      'code': code,
      'message': message,
      'data': data,
    });
    return Response(
      httpStatus,
      body: body,
      headers: {'content-type': 'application/json'},
    );
  }
}