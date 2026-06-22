import 'package:flutter/widgets.dart';

enum AppBreakpoint {
  compact,
  medium,
  expanded,
  wide;

  static AppBreakpoint fromWidth(double width) {
    if (width >= 1440) return AppBreakpoint.wide;
    if (width >= 1024) return AppBreakpoint.expanded;
    if (width >= 600) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }
}

class AppResponsiveSpec {
  const AppResponsiveSpec._();

  static bool usesBottomNavigation(double width) => width < 600;

  static bool usesDesktopNavigation(double width) => width >= 1024;

  static int homeActionColumns(double width) {
    return switch (AppBreakpoint.fromWidth(width)) {
      AppBreakpoint.compact => 2,
      AppBreakpoint.medium => 3,
      AppBreakpoint.expanded => 4,
      AppBreakpoint.wide => 6,
    };
  }

  static double contentMaxWidth(double width) {
    return switch (AppBreakpoint.fromWidth(width)) {
      AppBreakpoint.compact => 560,
      AppBreakpoint.medium => 920,
      AppBreakpoint.expanded => 1240,
      AppBreakpoint.wide => 1480,
    };
  }
}

extension AppBreakpointContext on BuildContext {
  AppBreakpoint get appBreakpoint =>
      AppBreakpoint.fromWidth(MediaQuery.sizeOf(this).width);
}
