import 'package:flutter/material.dart';

mixin LayoutMixin<T extends StatefulWidget> on State<T> {
  Future<bool> showBackDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认退出'),
            content: const Text('您确定要离开此页面吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确定'),
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
