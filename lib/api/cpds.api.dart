import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_kts_template/config/config.dart';
import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_models.dart';
import 'package:web_socket_channel/io.dart';

import '../utils/request/httpClient.dart';

class CpdsApi {
  CpdsApi._();

  static final Dio _dio = DioClient().dio;

  static Future<CpdsApplicationState> getState() async {
    final data = await _get('/state');
    return CpdsApplicationState.fromJson(_asMap(data));
  }

  static Future<CpdsApplicationState> uploadPackage(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw CpdsException(
        CpdsErrorCode.invalidPackage,
        params: {'field': 'package'},
        message: 'file bytes are empty',
      );
    }
    final formData = FormData.fromMap({
      'package': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    final data = await _post('/package/upload', data: formData);
    return CpdsApplicationState.fromJson(_asMap(data));
  }

  static Future<CpdsApplicationState> parsePackage() async {
    final data = await _post('/package/parse');
    return CpdsApplicationState.fromJson(_asMap(data));
  }

  static Future<CpdsApplicationState> selectNode(String nodeId) async {
    final data = await _post('/nodes/select', data: {'nodeId': nodeId});
    return CpdsApplicationState.fromJson(_asMap(data));
  }

  static Future<List<CpdsNetworkInterface>> listNetworkInterfaces() async {
    final data = await _get('/network-interfaces');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => CpdsNetworkInterface.fromJson(_asMap(item)))
        .toList();
  }

  static Future<CpdsApplicationState> selectNetworkInterface(
    String name,
  ) async {
    final data = await _post('/network-interfaces/select', data: {'name': name});
    return CpdsApplicationState.fromJson(_asMap(data));
  }

  static Future<CpdsApplicationState> startDistribution() async {
    final data = await _post('/distributions');
    return CpdsApplicationState.fromJson(_asMap(data));
  }

  static Future<CpdsApplicationState> resolveDiscoveryMismatch({
    required String sessionId,
    required bool proceed,
  }) async {
    final data = await _post(
      '/distributions/decision',
      data: {'sessionId': sessionId, 'proceed': proceed},
    );
    return CpdsApplicationState.fromJson(_asMap(data));
  }

  static StreamSubscription<CpdsApplicationState> subscribe(
    void Function(CpdsApplicationState state) onState,
  ) {
    final channel = IOWebSocketChannel.connect(_webSocketUri());
    return channel.stream.map((event) {
      final decoded = jsonDecode(event as String);
      return CpdsApplicationState.fromJson(_asMap(decoded));
    }).listen(onState);
  }

  static Future<dynamic> _get(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } on DioException catch (error) {
      throw _toCpdsException(error);
    }
  }

  static Future<dynamic> _post(
    String path, {
    Object? data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw _toCpdsException(error);
    }
  }

  static CpdsException _toCpdsException(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      final code = CpdsErrorCode.fromApiName(body['errorCode']);
      final params = _asMap(body['params']);
      return CpdsException(code, params: params);
    }
    return CpdsException(
      CpdsErrorCode.invalidMessage,
      params: {'cause': error.message ?? ''},
      message: error.message ?? 'request failed',
    );
  }

  static Uri _webSocketUri() {
    final base = Uri.parse(AppConfig.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final pathSegments = [...base.pathSegments, 'events'];
    return base.replace(scheme: scheme, pathSegments: pathSegments);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
