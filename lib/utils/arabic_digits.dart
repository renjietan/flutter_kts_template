import 'package:flutter/widgets.dart';

import '../i18n/handle/translations.g.dart';

/// 把 0-9 转成东阿拉伯数字（仅东阿拉伯语 ar_EG）；
/// 西阿拉伯语(ar_MA)/中文/英文保持 0-9 不变。
String localizeDigits(BuildContext context, String value) {
  final locale = TranslationProvider.of(context).locale;
  if (locale != AppLocale.arEg) return value;
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buffer.writeCharCode(0x660 + (rune - 0x30));
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
