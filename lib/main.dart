import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/auth/auth_session.dart';
import 'core/localization/app_localizations_x.dart';
import 'core/localization/locale_controller.dart';
import 'core/localization/locale_preferences.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.init();
  await AppLocaleStore.init();
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

class _BrowserAdaptiveApp extends ConsumerWidget {
  const _BrowserAdaptiveApp({required this.designSize});

  final Size designSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localePreference = ref.watch(appLocaleProvider);
    final activeLocale = resolveSupportedLocale(
      PlatformDispatcher.instance.locale,
      preference: localePreference,
    );
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
            ? viewportWidth
            : viewportWidth.clamp(320.0, 430.0);
        final frameHeight = viewportHeight;
        final viewData = MediaQueryData.fromView(View.of(context));

        final frameMediaQuery = viewData.copyWith(
          size: Size(frameWidth, frameHeight),
          padding: isBrowserWide ? EdgeInsets.zero : viewData.padding,
          viewPadding: isBrowserWide ? EdgeInsets.zero : viewData.viewPadding,
          viewInsets: isBrowserWide ? EdgeInsets.zero : viewData.viewInsets,
        );

        ScreenUtil.configure(
          data: frameMediaQuery,
          designSize: isBrowserWide
              ? Size(frameWidth, frameHeight)
              : designSize,
          minTextAdapt: true,
          splitScreenMode: true,
        );

        final framedApp = MediaQuery(
          data: frameMediaQuery,
          child: MaterialApp.router(
            onGenerateTitle: (context) => context.l10n.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightThemeFor(activeLocale),
            darkTheme: AppTheme.darkThemeFor(activeLocale),
            locale: localePreference.locale,
            supportedLocales: supportedAppLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (locale, supportedLocales) =>
                resolveSupportedLocale(
                  locale ?? const Locale('zh'),
                  preference: localePreference,
                ),
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return MediaQuery(
                data: frameMediaQuery,
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        );

        return framedApp;
      },
    );
  }
}
