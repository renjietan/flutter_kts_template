// http_client.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

import '../response/BaseResponse.dart';
import 'interceptor/error_interceptor.dart';

class DioClient {
  // 单例对象
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late Dio _dio;
  final CancelToken _cancelToken = CancelToken();

  DioClient._internal() {
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

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<BaseResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    required T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BaseResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required T Function(dynamic json)? fromJson,
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
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BaseResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    required T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BaseResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    required T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken ?? _cancelToken,
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  BaseResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic json)? fromJson,
  ) {
    if (response.statusCode == 200) {
      dynamic data = response.data;
      // return response.data;
      return BaseResponse<T>(
        code: data["code"],
        message: data["message"],
        data: fromJson == null
            ? data["data"]
            : fromJson(data["data"]), // 👈 用回调解析内部 data
      );
      ;
    } else {
      // HTTP 状态码错误
      throw HttpException(
        response.statusCode ?? -1,
        response.statusMessage ?? t.common.requestError,
      );
    }
  }

  Exception _handleError(dynamic error) {
    SimplePopup.hideLoading();
    Exception tipException = UnknownException(
      error.message ?? t.common.UnknowError,
    );
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.cancel:
          tipException = CancelException(t.common.requestCancel);
        case DioExceptionType.connectionTimeout:
          tipException = ConnectionTimeoutException(t.common.connectionTimeout);
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          tipException = NetWorkException(t.common.requestTimeout);
        case DioExceptionType.connectionError:
          tipException = ConnectionTimeoutException(t.common.connectionTimeout);
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? -1;
          final msg =
              (error.response?.data ?? {})["message"] ??
              error.response?.statusMessage ??
              t.common.serverError;
          tipException = HttpException(code, msg);
        default:
          tipException = UnknownException(
            error.message ?? t.common.UnknowError,
          );
      }
    }
    SimplePopup.error(
      tipException.toString(),
      duration: Duration(milliseconds: 1500),
    );
    return tipException;
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
  String toString() => '($code): $message';
}

class HttpException implements Exception {
  final int code;
  final String message;
  HttpException(this.code, this.message);
  @override
  String toString() => '($code): $message';
}

class ConnectionTimeoutException implements Exception {
  final String message;
  ConnectionTimeoutException(this.message);
  @override
  String toString() => message;
}

class NetWorkException implements Exception {
  final String message;
  NetWorkException(this.message);
  @override
  String toString() => message;
}

class CancelException implements Exception {
  final String message;
  CancelException(this.message);
  @override
  String toString() => message;
}

class UnknownException implements Exception {
  final String message;
  UnknownException(this.message);
  @override
  String toString() => message;
}
