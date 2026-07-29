import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/core/entities/keyLoaders/keyLoadersEntity.dart';

class KeyLoaderProvider with ChangeNotifier {
  List<KeyLoadersEntity> _keyLoaders;

  KeyLoaderProvider(this._keyLoaders);

  List<KeyLoadersEntity> get keyLoaders => _keyLoaders;

  set setKeyLoaders(List<KeyLoadersEntity> data) {
    _keyLoaders = data;
    notifyListeners();
  }
}
