// layout/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/layout/sideMenu/sideMenu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

import '../../config/config.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false, // 禁止直接返回
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 已处理弹出，则直接推出
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('确认退出？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('确定')),
            ],
          ),
        ) ?? false;

        if (shouldPop) {
          // 确认后主动调用 pop
          if (context.mounted) Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          // appbar 高度
          preferredSize: const Size.fromHeight(56.0),
          child: AppBar(
            title: const Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: false,
            backgroundColor: const Color(0xFF002250), // rgb(0,34,80)
            elevation: 0,
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20.w),
                    const SizedBox(width: 8),
                    const Text('v1.0'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: FlutterSmartDialog(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SideMenu(onSelected: _onDestinationSelected,),
              const VerticalDivider(thickness: 1, width: 1),
              // 右侧内容区 (当前活跃的分支页面)
              Expanded(
                child: navigationShell,
              ),
            ],
          ),
        )
      ),
    );
  }
}