import 'package:flutter/material.dart';

import '../../../i18n/handle/translations.g.dart';
import '../../../utils/shared.dart';

class SwitchLanguage extends StatefulWidget {
  const SwitchLanguage({super.key});

  @override
  State<SwitchLanguage> createState() => _SwitchLanguageState();
}

class _SwitchLanguageState extends State<SwitchLanguage> {
  late String currentLocale;
  Future<void> _toggleLocale() async {
    if (currentLocale == "zh") {
      await LocaleSettings.setLocale(AppLocale.en);
      await Shared.saveLocale(AppLocale.en.languageCode);
      if (mounted) {
        setState(() {
          currentLocale = "en";
        });
      }
    } else {
      await LocaleSettings.setLocale(AppLocale.zh);
      await Shared.saveLocale(AppLocale.zh.languageCode);
      if (mounted) {
        setState(() {
          currentLocale = "zh";
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement initState
    super.didChangeDependencies();
    currentLocale = TranslationProvider.of(context).locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(16),
        minimumSize: Size(80, 80),
        backgroundColor: Colors.transparent,
        iconColor: Colors.white70,
        foregroundColor: Colors.transparent,
        overlayColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      onPressed: _toggleLocale,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language),
          SizedBox(width: 5),
          Text(
            currentLocale == "zh" ? t.settings.zh : t.settings.en,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
