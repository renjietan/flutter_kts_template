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
}