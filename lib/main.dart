import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/auth/auth_session.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.init();
  DioClient.init();

  // Edge-to-Edge：让 Flutter 渲染延伸到状态栏和导航栏区域
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static const _iphone13DesignSize = Size(390, 844);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _BrowserAdaptiveApp(designSize: _iphone13DesignSize);
  }
}

class _BrowserAdaptiveApp extends StatelessWidget {
  const _BrowserAdaptiveApp({required this.designSize});

  final Size designSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : designSize.width;
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : designSize.height;
        final isBrowserWide = viewportWidth >= 560;
        final frameWidth = isBrowserWide
            ? designSize.width
            : viewportWidth.clamp(320.0, 430.0);
        final frameHeight = isBrowserWide
            ? (viewportHeight - 40).clamp(620.0, designSize.height)
            : viewportHeight;
        final viewData = MediaQueryData.fromView(View.of(context));

        final frameMediaQuery = viewData.copyWith(
          size: Size(frameWidth, frameHeight),
          padding: isBrowserWide ? EdgeInsets.zero : viewData.padding,
          viewPadding: isBrowserWide ? EdgeInsets.zero : viewData.viewPadding,
          viewInsets: isBrowserWide ? EdgeInsets.zero : viewData.viewInsets,
        );

        ScreenUtil.configure(
          data: frameMediaQuery,
          designSize: designSize,
          minTextAdapt: true,
          splitScreenMode: true,
        );

        final framedApp = MediaQuery(
          data: frameMediaQuery,
          child: MaterialApp.router(
            title: '江湖钓客',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return MediaQuery(
                data: frameMediaQuery,
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        );

        if (!isBrowserWide) {
          return framedApp;
        }

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1220), Color(0xFF111827), Color(0xFF0F172A)],
            ),
          ),
          child: Center(
            child: Container(
              width: frameWidth,
              height: frameHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: framedApp,
            ),
          ),
        );
      },
    );
  }
}
