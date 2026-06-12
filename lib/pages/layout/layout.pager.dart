import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/layout/layout.mixin.dart';
import 'package:flutter_kts_template/pages/layout/sideMenu/sideMenu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';

import '../../config/config.dart';
import '../../utils/provider/menu_provider.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> with LayoutMixin {
  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(builder: (context, status, child) {
      return PopScope(
        canPop: false, // 禁止直接返回
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return; // 已处理弹出，则直接推出
          // final shouldPop = await showBackDialog(context);
          // if (shouldPop == true && mounted) {
          //   Navigator.of(context).maybePop();
          // }
        },
        child: Scaffold(
          // 顶部标题栏
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
          body: Row(
            // 使三列高度撑满
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SideMenu(),
              // 中间区域 (flex 8)
              Expanded(
                  child: FlutterSmartDialog(
                      child: IndexedStack(
                        index: status.selectedIndex,
                        children: pages(context),
                      ),
                  )
              )
            ],
          ),
        ),
      );
    });
  }
}

