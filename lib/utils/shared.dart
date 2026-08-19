import 'package:flutter_kts_template/logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Shared {
  /// 内部构造方法，可避免外部暴露构造函数，进行实例化
  Shared._internal();

  static SharedPreferences? _spf;

  static Future<SharedPreferences> init() async {
    _spf ??= await SharedPreferences.getInstance();
    GlobalLogger.logInfo("Shared Start");
    return _spf!;
  }

  /// 用户信息
  static Future<bool> saveUserInfo(String nickName) {
    return _spf!.setString('key_nickname', nickName);
  }

  static String? getUserInfo() {
    return _spf!.getString('key_nickname');
  }

  static Future<bool> removeUserInfo() {
    return _spf!.clear();
  }

  static const String _cpdsNetworkInterfaceKey = 'cpds.networkInterface';
  static const String _cpdsLastSourcePathKey = 'cpds.lastSourcePath';

  static String? getCpdsNetworkInterface() {
    return _spf?.getString(_cpdsNetworkInterfaceKey);
  }

  static Future<bool> saveCpdsNetworkInterface(String name) {
    if (name.isEmpty) {
      return _spf?.remove(_cpdsNetworkInterfaceKey) ?? Future.value(false);
    }
    return _spf!.setString(_cpdsNetworkInterfaceKey, name);
  }

  static String? getCpdsLastSourcePath() {
    return _spf?.getString(_cpdsLastSourcePathKey);
  }

  static Future<bool> saveCpdsLastSourcePath(String path) {
    if (path.isEmpty) {
      return _spf?.remove(_cpdsLastSourcePathKey) ?? Future.value(false);
    }
    return _spf!.setString(_cpdsLastSourcePathKey, path);
  }

  static const String _cpdsLastUploadNameKey = 'cpds.lastUploadName';
  static const String _cpdsLastSelectedNodeKey = 'cpds.lastSelectedNode';

  static String? getCpdsLastUploadName() {
    return _spf?.getString(_cpdsLastUploadNameKey);
  }

  static String? getCpdsLastSelectedNode() {
    return _spf?.getString(_cpdsLastSelectedNodeKey);
  }

  static Future<void> saveCpdsLastUpload({
    required String path,
    required String name,
  }) async {
    await Future.wait([
      _spf!.setString(_cpdsLastSourcePathKey, path),
      _spf!.setString(_cpdsLastUploadNameKey, name),
    ]);
  }

  static Future<void> saveCpdsSelectedNode(String nodeId) {
    return _spf!.setString(_cpdsLastSelectedNodeKey, nodeId);
  }
}
