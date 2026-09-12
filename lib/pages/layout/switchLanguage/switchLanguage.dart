import 'package:flutter/material.dart';

import '../../../i18n/handle/translations.g.dart';
import '../../../utils/shared.dart';

class SwitchLanguage extends StatefulWidget {
  const SwitchLanguage({super.key});

  @override
  State<SwitchLanguage> createState() => _SwitchLanguageState();
}

class _SwitchLanguageState extends State<SwitchLanguage> {
  late AppLocale currentLocale;

  String _localeKey(AppLocale locale) {
    final cc = locale.countryCode;
    return cc == null ? locale.languageCode : '${locale.languageCode}_$cc';
  }

  String _label(AppLocale locale) {
    switch (locale) {
      case AppLocale.zh:
        return t.settings.zh;
      case AppLocale.en:
        return t.settings.en;
      case AppLocale.arEg:
        return t.settings.arEg;
      case AppLocale.arMa:
        return t.settings.arMa;
    }
  }

  Future<void> _selectLocale(AppLocale locale) async {
    await LocaleSettings.setLocale(locale);
    await Shared.saveLocale(_localeKey(locale));
    if (mounted) {
      setState(() {
        currentLocale = locale;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentLocale = TranslationProvider.of(context).locale;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppLocale>(
      onSelected: _selectLocale,
      itemBuilder: (context) => [
        PopupMenuItem(value: AppLocale.zh, child: Text(_label(AppLocale.zh))),
        PopupMenuItem(value: AppLocale.en, child: Text(_label(AppLocale.en))),
        PopupMenuItem(value: AppLocale.arEg, child: Text(_label(AppLocale.arEg))),
        PopupMenuItem(value: AppLocale.arMa, child: Text(_label(AppLocale.arMa))),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Colors.white70),
            const SizedBox(width: 5),
            Text(
              _label(currentLocale),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}