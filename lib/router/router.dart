import 'package:flutter/cupertino.dart';
import 'dart:typed_data';
import 'package:flutter_kts_template/core/databaseManager/databaseManager.dart';
import 'package:flutter_kts_template/core/entities/installPackage/installPackageEntity.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_repository.dart';
import 'package:flutter_kts_template/core/selfUpdate/install_package_storage.dart';
import 'package:flutter_kts_template/core/selfUpdate/self_update_service.dart';
import 'package:flutter_kts_template/pages/cpds/cpds.page.dart';
import 'package:flutter_kts_template/pages/keyLoader/keyLoader.pager.dart';
import 'package:flutter_kts_template/pages/layout/layout.pager.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:flutter_kts_template/pages/self_update/self_update.pager.dart';
import 'package:flutter_kts_template/utils/provider/user.provider.dart';
import 'package:flutter_kts_template/utils/files/pick_files/FileSelector.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../theme/table.theme.dart';

// final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<StatefulNavigationShellState> _layoutKey =
    GlobalKey<StatefulNavigationShellState>();
final GlobalKey<NavigatorState> _cpdsKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _radioManagerKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _injectEncryptStickKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _selfUpdateKey = GlobalKey<NavigatorState>();

Future<Uint8List?> _pickZipFile() async {
  final file = await FileSelector.pickFile(['zip']);
  return file?.bytes;
}

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/cpds',
  redirect: (context, state) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userInfo = userProvider.userInfo;
    final bool isLoggingIn = state.matchedLocation == '/login';
    if (userInfo.isEmpty) {
      // 登录页面无需 重定向
      return isLoggingIn ? null : '/login';
    }
    if (isLoggingIn) {
      return '/cpds';
    }
    // 无需重定向时，需要返回 null
    return null;
  },
  routes: [
    // GoRoute(
    //   path: '/splash',
    //   name: 'splash',
    //   builder: (context, state) => const SplashPage(),
    // ),
    StatefulShellRoute.indexedStack(
      key: _layoutKey,
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _cpdsKey,
          routes: [
            GoRoute(
              parentNavigatorKey: _cpdsKey,
              path: '/cpds',
              name: 'cpds',
              builder: (context, state) => const CpdsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _radioManagerKey,
          routes: [
            GoRoute(
              parentNavigatorKey: _radioManagerKey,
              path: '/radioManager',
              name: 'radioManager',
              builder: (context, state) => RadioManagerPager(
                theme: getThemePreset(ThemePreset.dark),
                themePreset: ThemePreset.dark,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _injectEncryptStickKey,
          routes: [
            GoRoute(
              path: '/injectEncryptStick',
              name: 'injectEncryptStick',
              parentNavigatorKey: _injectEncryptStickKey,
              builder: (context, state) => KeyLoaderPager(
                theme: getThemePreset(ThemePreset.dark),
                themePreset: ThemePreset.dark,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _selfUpdateKey,
          routes: [
            GoRoute(
              parentNavigatorKey: _selfUpdateKey,
              path: '/selfUpdate',
              name: 'selfUpdate',
              builder: (context, state) => SelfUpdatePager(
                service: SelfUpdateService(
                  repository: InstallPackageRepository(
                    DatabaseManager.instance.box<InstallPackageEntity>(),
                  ),
                  storage: InstallPackageStorage(),
                ),
                pickZipFile: _pickZipFile,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
