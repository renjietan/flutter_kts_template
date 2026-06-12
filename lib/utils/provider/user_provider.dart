import 'package:flutter/cupertino.dart';

import '../shared.dart';

///用户账户信息
class UserProvider with ChangeNotifier {
  String? _userInfo;

  UserProvider(this._userInfo);

  String get userInfo => _userInfo!;

  set userInfo(String? userInfo) {
    _userInfo = userInfo;
    Shared.saveUserInfo(userInfo!);
    notifyListeners();
  }
}