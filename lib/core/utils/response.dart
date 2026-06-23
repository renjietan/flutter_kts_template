import 'dart:convert';

import 'package:shelf/shelf.dart';

class ApiResponse {
  final int code;
  final String message;
  final dynamic data;

  ApiResponse({required this.code, required this.message, this.data});

  static Response success({dynamic data, String message = 'success'}) {
    return _response(code: 200, message: message, data: data, httpStatus: 200);
  }

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

  static Response unauthorized({
    String message = 'unauthorized',
    dynamic data,
  }) {
    return _response(code: 401, message: message, data: data, httpStatus: 401);
  }

  /// 禁止访问 (HTTP 403)
  static Response forbidden({String message = 'forbidden', dynamic data}) {
    return _response(code: 403, message: message, data: data, httpStatus: 403);
  }

  static Response notFound({String message = 'not found', dynamic data}) {
    return _response(code: 404, message: message, data: data, httpStatus: 404);
  }

  static Response internalError({
    String message = 'internal server error',
    dynamic data,
  }) {
    return _response(code: 500, message: message, data: data, httpStatus: 500);
  }

  static Response _response({
    required int code,
    required String message,
    dynamic data,
    required int httpStatus,
  }) {
    final body = jsonEncode({'code': code, 'message': message, 'data': data});
    return Response(
      httpStatus,
      body: body,
      headers: {'content-type': 'application/json'},
    );
  }
}
