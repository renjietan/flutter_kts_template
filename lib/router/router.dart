import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/pages/InjectEncryptionStick/InjectEncryptionStick.pager.dart';
import 'package:flutter_kts_template/pages/layout/layout.pager.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:flutter_kts_template/pages/splash/splash.dart';
import 'package:go_router/go_router.dart';

import '../main.dart';
import '../pages/paramsInject/paramsInject.pager.dart';
import '../theme/table.theme.dart';

// final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<StatefulNavigationShellState> _layoutKey =
    GlobalKey<StatefulNavigationShellState>();
final GlobalKey<NavigatorState> _radioManagerKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _paramsInjectKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _injectEncryptStickKey =
    GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    // final currentPath = state.uri.path;

    // // 如果不在启动页，且未登录，则重定向到登录页
    // if (!_isLoggedIn && currentPath != '/login' && currentPath != '/splash') {
    //   return '/login';
    // }
    // // 如果已登录，且当前在登录页或启动页，则重定向到主页
    // if (_isLoggedIn && (currentPath == '/login' || currentPath == '/splash')) {
    //   return '/radioManager';
    // }
    // 其他情况不重定向
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    StatefulShellRoute.indexedStack(
      key: _layoutKey,
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _paramsInjectKey,
          routes: [
            GoRoute(
              parentNavigatorKey: _paramsInjectKey,
              path: '/paramsInject',
              name: 'paramsInject',
              builder: (context, state) => ParamsInjectPager(),
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
              builder: (context, state) => InjectEncryptionStickPager(
                theme: getThemePreset(ThemePreset.dark),
                themePreset: ThemePreset.dark,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
