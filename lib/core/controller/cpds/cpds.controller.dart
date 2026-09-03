import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_kts_template/core/cpds/cpds_exception.dart';
import 'package:flutter_kts_template/core/cpds/model/cpds_enums.dart';
import 'package:flutter_kts_template/core/cpds/service/cpds_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_essentials/shelf_essentials.dart';

class CpdsController {
  static Future<Response> getState(Request request) async {
    return _ok(CpdsManager.instance.state().toJson());
  }

  static Future<Response> upload(Request request) async {
    try {
      final form = await request.formData();
      final file = form.files['package'];
      if (file == null) {
        throw CpdsException(
          CpdsErrorCode.invalidPackage,
          params: {'field': 'package'},
          message: 'package file is missing',
        );
      }
      final bytes = Uint8List.fromList(await file.readAsBytes());
      final state = await CpdsManager.instance.uploadPackage(
        file.name,
        bytes,
      );
      return _ok(state.toJson());
    } on CpdsException {
      rethrow;
    } catch (error) {
      throw CpdsException(
        CpdsErrorCode.storageIoError,
        params: {'cause': error.toString()},
        message: 'upload failed',
      );
    }
  }

  static Future<Response> parse(Request request) async {
    final state = await CpdsManager.instance.parsePackage();
    return _ok(state.toJson());
  }

  static Future<Response> parseSourcePath(Request request) async {
    final body = _readBody(request);
    final sourcePath = body['path']?.toString() ?? '';
    final state = await CpdsManager.instance.parseSourcePath(sourcePath);
    return _ok(state.toJson());
  }

  static Response selectNode(Request request) {
    final body = _readBody(request);
    final nodeId = body['nodeId']?.toString() ?? '';
    final state = CpdsManager.instance.selectNode(nodeId);
    return _ok(state.toJson());
  }

  static Response selectFutureWarrior(Request request) {
    final body = _readBody(request);
    final unitId = body['unitId']?.toString() ?? '';
    final state = CpdsManager.instance.selectFutureWarrior(unitId);
    return _ok(state.toJson());
  }

  static Future<Response> listNetworkInterfaces(Request request) async {
    final interfaces = await CpdsManager.instance.listNetworkInterfaces();
    return Response.ok(
      jsonEncode(interfaces.map((item) => item.toJson()).toList()),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  static Future<Response> selectNetworkInterface(Request request) async {
    final body = _readBody(request);
    final name = body['name']?.toString() ?? '';
    final state = await CpdsManager.instance.selectNetworkInterface(name);
    return _ok(state.toJson());
  }

  static Future<Response> startDistribution(Request request) async {
    await CpdsManager.instance.startDistribution();
    return _ok(CpdsManager.instance.state().toJson());
  }

  static Future<Response> resolveDiscoveryMismatch(Request request) async {
    final body = _readBody(request);
    final sessionId = body['sessionId']?.toString() ?? '';
    final proceed = body['proceed'] as bool? ?? false;
    await CpdsManager.instance.resolveDiscoveryMismatch(sessionId, proceed);
    return _ok(CpdsManager.instance.state().toJson());
  }

  static Map<String, dynamic> _readBody(Request request) {
    final value = request.context['params'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static Response _ok(Map<String, dynamic> data) {
    return Response.ok(
      jsonEncode(data),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

}
