import 'package:flutter/cupertino.dart';

import '../../core/entities/radios/radiosEntity.dart';

class RadiosProvider with ChangeNotifier {
  List<RadiosEntity> _radios;

  RadiosProvider(this._radios);

  List<RadiosEntity> get radios => _radios;

  set setRadios(List<RadiosEntity> data) {
    _radios = data;
    notifyListeners();
  }
}
