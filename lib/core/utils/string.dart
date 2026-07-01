import 'dart:convert';

import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

class StringTools {
  static Map<String, dynamic>? string2Map(String str) {
    try {
      var data = jsonDecode(str);
      return data;
    } on FormatException catch (e) {
      SimplePopup.error(t.json.serialization);
    }
    return null;
  }
}
