import 'package:flutter_kts_template/pages/layout/layout.pager.dart';
import 'package:flutter_kts_template/pages/splash/splash.dart';
import 'package:go_router/go_router.dart';

import '../pages/test.dart';

final routers = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'splash',
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      name: 'home',
      path: '/home',
      builder: (context, state) => const LayoutPage(),
    ),
    GoRoute(
      name: 'test',
      path: '/test',
      builder: (context, state) => const TestTreeView(),
    ),
  ],
);