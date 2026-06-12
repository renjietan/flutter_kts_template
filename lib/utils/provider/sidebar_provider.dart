import 'package:flutter/cupertino.dart';


class SideBarProvider with ChangeNotifier {
  bool _isExpanded;

  SideBarProvider(this._isExpanded);

  bool get isExpanded => _isExpanded;

  set tabIndex(bool isExpanded) {
    _isExpanded = isExpanded;
    notifyListeners();
  }
}