// layout/main_layout.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/pages/layout/sideMenu/sideMenu.dart';
import 'package:flutter_kts_template/pages/layout/switchLanguage/switchLanguage.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../config/config.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: (index == 2) || (index == navigationShell.currentIndex),
    );
  }

  Future<void> _clearTempFiles() async {
    final dir = Directory(await DirectoryManager.instance.getZipCache());
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
    SimplePopup.success('操作成功');
  }

  Future<void> _clearCache() async {
    final dir = Directory(await DirectoryManager.instance.getUploadsPath());
    if (!await dir.exists()) return;

    final pcFiles = <File>[];
    final zipFiles = <File>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final lower = entity.path.toLowerCase();
      if (lower.endsWith('.pc')) {
        pcFiles.add(entity);
      } else if (lower.endsWith('.zip')) {
        zipFiles.add(entity);
      }
    }

    void sortDesc(List<File> files) {
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
    }

    Future<void> deleteExceptFirst(List<File> files) async {
      if (files.length <= 1) return;
      sortDesc(files);
      for (final file in files.sublist(1)) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    await deleteExceptFirst(pcFiles);
    await deleteExceptFirst(zipFiles);
    SimplePopup.success('操作成功');
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeWidget(
      child: Scaffold(
        // 键盘弹起时，页面重新调整大小以适应键盘
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon(HyIcons., size: 20),
                const SizedBox(width: 5),
                Image.asset(
                  'assets/appbar/logo.png',
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 7),
                const Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            centerTitle: false,
            backgroundColor: const Color(0xFF002250),
            elevation: 0,
            foregroundColor: Colors.white,
            actions: [
              // Padding(
              //   padding: const EdgeInsets.only(right: 16.0),
              //   child: Row(
              //     children: [
              //       Icon(Icons.info_outline, size: 20.w),
              //       const SizedBox(width: 8),
              //       const Text('v1.0'),
              //     ],
              //   ),
              // ),
              SwitchLanguage(),
              PopupMenuButton<_LayoutSettingAction>(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: '设置',
                onSelected: (action) {
                  switch (action) {
                    case _LayoutSettingAction.clearTemp:
                      unawaited(_clearTempFiles());
                    case _LayoutSettingAction.clearCache:
                      unawaited(_clearCache());
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _LayoutSettingAction.clearTemp,
                    child: Text('清除临时文件'),
                  ),
                  PopupMenuItem(
                    value: _LayoutSettingAction.clearCache,
                    child: Text('清除缓存'),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // 关闭当前所有输入框的键盘
            FocusScope.of(context).unfocus();
          },
          child: FlutterSmartDialog(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x8A00A2E9), width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SideMenu(onSelected: _onDestinationSelected),
                  const VerticalDivider(thickness: 1, width: 1),
                  // 右侧内容区 (当前活跃的分支页面)
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _LayoutSettingAction { clearTemp, clearCache }
