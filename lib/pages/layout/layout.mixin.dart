import 'package:flutter/material.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';

mixin LayoutMixin<T extends StatefulWidget> on State<T> {
  Future<bool> showBackDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.t.layout.confirmExit),
            content: Text(context.t.layout.leavePagePrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.t.common.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.t.tips.ok),
              ),
            ],
          ),
        ) ??
        false; // 如果对话框关闭（如点击外部），则默认不允许返回
  }

  @override
  void initState() {
    super.initState();
  }
}
