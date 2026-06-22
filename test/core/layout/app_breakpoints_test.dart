import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/core/layout/app_breakpoints.dart';

void main() {
  test('classifies the four supported responsive ranges', () {
    expect(AppBreakpoint.fromWidth(375), AppBreakpoint.compact);
    expect(AppBreakpoint.fromWidth(768), AppBreakpoint.medium);
    expect(AppBreakpoint.fromWidth(1024), AppBreakpoint.expanded);
    expect(AppBreakpoint.fromWidth(1440), AppBreakpoint.wide);
  });

  test('chooses stable home action columns for each range', () {
    expect(AppResponsiveSpec.homeActionColumns(390), 2);
    expect(AppResponsiveSpec.homeActionColumns(768), 3);
    expect(AppResponsiveSpec.homeActionColumns(1180), 4);
    expect(AppResponsiveSpec.homeActionColumns(1440), 6);
  });

  test('uses rail navigation from tablet widths onward', () {
    expect(AppResponsiveSpec.usesBottomNavigation(599), isTrue);
    expect(AppResponsiveSpec.usesBottomNavigation(600), isFalse);
    expect(AppResponsiveSpec.usesDesktopNavigation(1023), isFalse);
    expect(AppResponsiveSpec.usesDesktopNavigation(1024), isTrue);
  });
}
