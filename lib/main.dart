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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: '江湖钓客',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                final double maxHeight = constraints.maxHeight;
                
                final bool isWide = maxWidth > 500;
                final double targetWidth = isWide ? 430.0 : maxWidth;
                
                final mediaQuery = MediaQuery.of(context);
                final constrainedQuery = mediaQuery.copyWith(
                  size: Size(targetWidth, maxHeight),
                );
                
                return MediaQuery(
                  data: constrainedQuery,
                  child: Builder(
                    builder: (context) {
                      ScreenUtil.init(
                        context,
                        designSize: const Size(375, 812),
                        minTextAdapt: true,
                        splitScreenMode: true,
                      );
                      
                      final content = child ?? const SizedBox.shrink();
                      
                      if (isWide) {
                        return Container(
                          color: const Color(0xFF062F32), // 使用水墨主题的主色作为网页背景
                          alignment: Alignment.center,
                          child: Container(
                            width: targetWidth,
                            height: maxHeight,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.36),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: content,
                          ),
                        );
                      }
                      
                      return content;
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
