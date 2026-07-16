import 'package:flutter/material.dart';

import '../../i18n/handle/translations.g.dart';

void SimpleTipsDialog(
  BuildContext ctx, {
  String title = "",
  String contentText = "",
  String cancelText = "",
  String okText = "",
  required void Function() func,
}) {
  showDialog(
    context: ctx,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title.isEmpty ? t.tips.title : title),
        content: Text(contentText),
        actions: <Widget>[
          TextButton(
            child: Text(cancelText.isEmpty ? t.tips.cancel : cancelText),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(okText.isEmpty ? t.tips.ok : okText),
            onPressed: () {
              func();
              Navigator.pop(context); // 保存完再关闭
            },
          ),
        ],
      );
    },
  );
}
