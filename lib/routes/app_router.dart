import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_session.dart';
import '../features/auth/view/login_screen.dart';
import '../features/community/view/community_screen.dart';
import '../features/creation/view/creation_modal_screen.dart';
import '../features/devices/view/device_alerts_screen.dart';
import '../features/devices/view/device_binding_screen.dart';
import '../features/devices/view/device_center_screen.dart';
import '../features/devices/view/device_command_screen.dart';
import '../features/devices/view/device_detail_screen.dart';
import '../features/devices/view/device_scenes_screen.dart';
import '../features/explore/view/explore_screen.dart';
import '../features/explore/view/spot_detail_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/main_shell/view/main_shell_screen.dart';
import '../features/mall/view/mall_cart_screen.dart';
import '../features/mall/view/mall_checkout_screen.dart';
import '../features/mall/view/mall_product_detail_screen.dart';
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
                pageBuilder: (context, state) {
                  final params = state.uri.queryParameters;
                  return _inkPage(
                    state,
                    ExploreScreen(
                      initialSpot: params['spot'],
                      initialFish: params['fish'],
                      initialWindow: params['window'],
                      initialHint: params['hint'],
                      initialIntent: params['intent'],
                      entry: params['entry'],
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouteNames.mall,
                pageBuilder: (context, state) {
                  final params = state.uri.queryParameters;
                  return _inkPage(
                    state,
                    MallScreen(
                      initialIntent: params['intent'],
                      initialQuery: params['query'] ?? params['fish'],
                      initialFish: params['fish'],
                      initialMethod: params['method'],
                      initialWindow: params['window'],
                      entry: params['entry'],
                    ),
                  );
                },
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
        path: AppRouteNames.mallCart,
        name: 'MallCart',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const MallCartScreen()),
      ),
      GoRoute(
        path: AppRouteNames.mallCheckout,
        name: 'MallCheckout',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const MallCheckoutScreen()),
      ),
      GoRoute(
        path: AppRouteNames.mallProductDetail,
        name: 'MallProductDetail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final productId = state.uri.queryParameters['id'] ?? '';
          return _inkPage(state, MallProductDetailScreen(productId: productId));
        },
      ),
      GoRoute(
        path: AppRouteNames.spotDetail,
        name: 'SpotDetail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final spotName = state.uri.queryParameters['name'] ?? '附近钓点';
          return _inkPage(state, SpotDetailScreen(spotName: spotName));
        },
      ),
      GoRoute(
        path: AppRouteNames.creationModal,
        name: 'CreationModal',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final params = state.uri.queryParameters;
          return _modalPage(
            state,
            CreationModalScreen(
              initialSpot: params['spot'],
              initialFish: params['fish'],
              initialMethod: params['method'],
              initialWindow: params['window'],
              initialHint: params['hint'],
              entry: params['entry'],
            ),
          );
        },
      ),
      GoRoute(
        path: AppRouteNames.community,
        name: 'Community',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const CommunityScreen()),
      ),
      GoRoute(
        path: AppRouteNames.settings,
        name: 'Settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRouteNames.devices,
        name: 'Devices',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const DeviceCenterScreen()),
      ),
      GoRoute(
        path: AppRouteNames.deviceAdd,
        name: 'DeviceAdd',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const DeviceBindingScreen()),
      ),
      GoRoute(
        path: AppRouteNames.deviceDetail,
        name: 'DeviceDetail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _inkPage(
          state,
          DeviceDetailScreen(deviceId: state.pathParameters['deviceId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRouteNames.deviceScenes,
        name: 'DeviceScenes',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const DeviceScenesScreen()),
      ),
      GoRoute(
        path: AppRouteNames.deviceAlerts,
        name: 'DeviceAlerts',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _inkPage(state, const DeviceAlertsScreen()),
      ),
      GoRoute(
        path: AppRouteNames.deviceCommand,
        name: 'DeviceCommand',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _inkPage(
          state,
          DeviceCommandScreen(
            commandId: state.pathParameters['commandId'] ?? '',
          ),
        ),
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
