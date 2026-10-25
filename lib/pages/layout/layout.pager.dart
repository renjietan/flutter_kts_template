// ignore_for_file: cpd_lints/hardcoded_dimension
// layout/main_layout.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/loading/simple.loading.dart';
import 'package:flutter_kts_template/core/utils/director.dart';
import 'package:flutter_kts_template/i18n/handle/translations.g.dart';
import 'package:flutter_kts_template/pages/layout/sideMenu/sideMenu.dart';
import 'package:flutter_kts_template/pages/layout/switchLanguage/switchLanguage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    SimplePopup.success(t.common.OperationSuccess);
  }

  Future<void> _clearCache() async {
    final dir = Directory(await DirectoryManager.instance.getUploadsPath());
    if (!await dir.exists()) return;

    final pcFiles = <File>[];
    final padFiles = <File>[];
    final zipFiles = <File>[];
    final toDelete = <FileSystemEntity>[];

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        toDelete.add(entity);
        continue;
      }
      if (entity is! File) continue;
      final lower = entity.path.toLowerCase();
      if (lower.endsWith('.cpdata')) {
        pcFiles.add(entity);
      } else if (lower.endsWith('.pad')) {
        padFiles.add(entity);
      } else if (lower.endsWith('.zip')) {
        zipFiles.add(entity);
      } else {
        toDelete.add(entity);
      }
    }

    for (final entity in toDelete) {
      try {
        if (entity is Directory) {
          await entity.delete(recursive: true);
        } else {
          await entity.delete();
        }
      } catch (_) {}
    }

    Future<void> deleteExceptFirst(List<File> files) async {
      if (files.length <= 1) return;
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      for (final file in files.sublist(1)) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    await deleteExceptFirst(pcFiles);
    await deleteExceptFirst(padFiles);
    await deleteExceptFirst(zipFiles);
    SimplePopup.success(t.common.OperationSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeWidget(
      child: Scaffold(
        // 键盘弹起时，页面重新调整大小以适应键盘
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: AppBar(
            primary: true,
            toolbarHeight: 48.h,
            title: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon(HyIcons., size: 20),
                SizedBox(width: 5.w),
                Image.asset(
                  'assets/appbar/logo.png',
                  height: 20.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 7.w),
                Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 18.sp,
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
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: const _AppVersionLabel(),
              ),
              SwitchLanguage(),
              PopupMenuButton<_LayoutSettingAction>(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: context.t.layout.settings,
                onSelected: (action) {
                  switch (action) {
                    case _LayoutSettingAction.clearTemp:
                      unawaited(_clearTempFiles());
                    case _LayoutSettingAction.clearCache:
                      unawaited(_clearCache());
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _LayoutSettingAction.clearTemp,
                    child: Text(context.t.layout.clearTempFiles),
                  ),
                  PopupMenuItem(
                    value: _LayoutSettingAction.clearCache,
                    child: Text(context.t.layout.clearCache),
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

class _AppVersionLabel extends StatefulWidget {
  const _AppVersionLabel();

  @override
  State<_AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<_AppVersionLabel> {
  // 打包脚本通过 --dart-define=APP_VERSION=x.y.z.n 注入显示版本（例如 0.1.5.3），
  // 避免 Android 上 package_info 返回的 versionCode 带 ABI 偏移（如 2003）。
  static const String _injectedVersion = String.fromEnvironment('APP_VERSION');

  late final Future<PackageInfo> _future = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    if (_injectedVersion.isNotEmpty) {
      return Text(
        'V$_injectedVersion',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      );
    }
    return FutureBuilder<PackageInfo>(
      future: _future,
      builder: (context, snapshot) {
        final info = snapshot.data;
        var version = '';
        if (info != null) {
          version = info.version;
          final build = _normalizedBuildNumber(info.buildNumber);
          if (build.isNotEmpty) {
            version = '$version.$build';
          }
        }
        return Text(
          version.isEmpty ? '' : 'V$version',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        );
      },
    );
  }

  /// Android 使用 `--split-per-abi` 时，`versionCode` 会被 Flutter 加上 ABI 偏移
  /// （arm32=1000、arm64=2000、x86_64=4000），取余 1000 还原真实的 build 号。
  /// Windows / iOS 无此偏移，直接返回原值。
  static String _normalizedBuildNumber(String raw) {
    if (defaultTargetPlatform != TargetPlatform.android) return raw;
    final code = int.tryParse(raw);
    if (code != null && code >= 1000) {
      return '${code % 1000}';
    }
    return raw;
  }
}
