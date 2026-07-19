import 'package:flutter/cupertino.dart';
import 'package:flutter_kts_template/pages/InjectEncryptionStick/InjectEncryptionStick.pager.dart';
import 'package:flutter_kts_template/pages/layout/layout.pager.dart';
import 'package:flutter_kts_template/pages/radioManager/radioManager.pager.dart';
import 'package:flutter_kts_template/utils/provider/user.provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  initialLocation: '/paramsInject',
  redirect: (context, state) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userInfo = userProvider.userInfo;
    final bool isLoggingIn = state.matchedLocation == '/login';
    if (userInfo.isEmpty) {
      // 登录页面无需 重定向
      return isLoggingIn ? null : '/login';
    }
    if (isLoggingIn) {
      return '/paramsInject';
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
