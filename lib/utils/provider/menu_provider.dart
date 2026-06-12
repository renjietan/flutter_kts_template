import 'package:flutter/cupertino.dart';

/// 状态管理
class MenuProvider with ChangeNotifier {
  //主页tab的索引
  int _selectedIndex = 0;

  MenuProvider(this._selectedIndex);

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}