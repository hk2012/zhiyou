import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_session.dart';
import '../features/auth/view/login_screen.dart';
import '../features/community/view/community_screen.dart';
import '../features/creation/view/creation_modal_screen.dart';
import '../features/explore/view/explore_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/main_shell/view/main_shell_screen.dart';
import '../features/mall/view/mall_screen.dart';
import '../features/profile/view/profile_screen.dart';
import '../features/profile/view/settings_screen.dart';
import '../shared/widgets/app_state_views.dart';
import '../shared/widgets/ink_app_widgets.dart';
import 'app_route_names.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static CustomTransitionPage<void> _modalPage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      opaque: false,
      barrierDismissible: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return InkPageTransition(animation: animation, child: child);
      },
    );
  }

  static CustomTransitionPage<void> _inkPage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return InkPageTransition(animation: animation, child: child);
      },
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRouteNames.home,
    redirect: (context, state) {
      final isLoggedIn = AuthSession.isLoggedIn;
      final isLoggingIn = state.matchedLocation == AppRouteNames.login;
      if (!isLoggedIn && !isLoggingIn) return AppRouteNames.login;
      if (isLoggedIn && isLoggingIn) return AppRouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRouteNames.login,
        name: 'Login',
        pageBuilder: (context, state) => _inkPage(state, const LoginScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouteNames.home,
                pageBuilder: (context, state) =>
                    _inkPage(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouteNames.explore,
                pageBuilder: (context, state) =>
                    _inkPage(state, const ExploreScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouteNames.community,
                pageBuilder: (context, state) =>
                    _inkPage(state, const CommunityScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouteNames.profile,
                pageBuilder: (context, state) =>
                    _inkPage(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRouteNames.creationModal,
        name: 'CreationModal',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _modalPage(state, const CreationModalScreen()),
      ),
      GoRoute(
        path: AppRouteNames.mall,
        name: 'Mall',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _inkPage(state, const MallScreen()),
      ),
      GoRoute(
        path: AppRouteNames.settings,
        name: 'Settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const SettingsScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: AppErrorView(
        title: '页面不存在',
        message: state.error?.toString(),
        actionLabel: '返回首页',
        onAction: () => context.go(AppRouteNames.home),
      ),
    ),
  );
}
