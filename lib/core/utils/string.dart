import 'dart:convert';

import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/logger/logger.dart';

class StringTools {
  static Map<String, dynamic>? string2Map(String str) {
    try {
      var data = jsonDecode(str);
      return data;
    } on FormatException catch (e) {
      GlobalLogger.logError(e.message);
      SimplePopup.error(t.json.serialization);
    }
    return null;
  }
}
