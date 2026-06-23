// http_client.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/utils/request/response.dart';

import 'interceptor/error_interceptor.dart';

class HttpClient {
  // 单例对象
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;

  late Dio _dio;
  final CancelToken _cancelToken = CancelToken();

  HttpClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // 添加拦截器
    _dio.interceptors.addAll([
      // 请求日志拦截器（开发环境打印）
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
      ErrorInterceptor(),
    ]);
  }

  // 获取 Dio 实例（允许外部直接使用）
  Dio get dio => _dio;

  // 重置/更新 BaseOptions（如切换环境）
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  // 添加额外拦截器（外部传入）
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  // ----- 封装 GET 请求 -----
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    required T Function(dynamic) parser, // 解析器
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response, parser);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response, parser);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
      );
      return _handleResponse(response, parser);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
      );
      return _handleResponse(response, parser);
    } catch (e) {
      throw _handleError(e);
    }
  }

  T _handleResponse<T>(Response response, T Function(dynamic) parser) {
    if (response.statusCode == 200) {
      final json = response.data;
      if (json is Map<String, dynamic>) {
        final entity = ResponseEntity<T>.fromJson(json, parser);
        if (entity.isSuccess) {
          return entity.data as T;
        } else {
          // 业务错误，抛出异常并携带后端返回的 message
          throw BusinessException(entity.code, entity.message);
        }
      } else {
        // 如果后端直接返回数据（非标准格式），依然可以通过 parser 解析
        return parser(json);
      }
    } else {
      // HTTP 状态码错误
      throw HttpException(
        response.statusCode ?? -1,
        response.statusMessage ?? '请求失败',
      );
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.cancel:
          return CancelException('请求被取消');
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetWorkException('网络超时，请稍后重试');
        case DioExceptionType.connectionError:
          return NetWorkException('网络连接失败，请检查网络');
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? -1;
          final msg = error.response?.statusMessage ?? '服务器异常';
          return HttpException(code, msg);
        default:
          return UnknownException(error.message ?? '未知错误');
      }
    }
    return UnknownException(error.toString());
  }

  void cancelRequests({CancelToken? cancelToken}) {
    if (cancelToken != null) {
      cancelToken.cancel('手动取消');
    } else {
      _cancelToken.cancel('手动取消全部请求');
    }
  }

  CancelToken newCancelToken() => CancelToken();
}

class BusinessException implements Exception {
  final int code;
  final String message;
  BusinessException(this.code, this.message);
  @override
  String toString() => 'BusinessException ($code): $message';
}

class HttpException implements Exception {
  final int code;
  final String message;
  HttpException(this.code, this.message);
  @override
  String toString() => 'HttpException ($code): $message';
}

class NetWorkException implements Exception {
  final String message;
  NetWorkException(this.message);
  @override
  String toString() => 'NetWorkException $message';
}

class CancelException implements Exception {
  final String message;
  CancelException(this.message);
  @override
  String toString() => 'CancelException $message';
}

class UnknownException implements Exception {
  final String message;
  UnknownException(this.message);
  @override
  String toString() => 'UnknownException: $message';
}
