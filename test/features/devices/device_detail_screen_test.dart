import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/features/devices/data/device_center_demo_data.dart';
import 'package:zhiyou_app/features/devices/view/device_detail_screen.dart';

void main() {
  Future<void> pumpDetail(WidgetTester tester, String deviceId) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) {
            return MaterialApp(
              home: DeviceDetailBody(bundle: demoDeviceBundle(deviceId)),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tackle box exposes common tabs and primary controls', (
    tester,
  ) async {
    await pumpDetail(tester, 'box_cool_01');

    expect(find.text('状态'), findsOneWidget);
    expect(find.text('控制'), findsOneWidget);
    expect(find.text('自动化'), findsOneWidget);
    expect(find.text('维护'), findsOneWidget);
    expect(find.text('温度设定'), findsOneWidget);
    expect(find.text('箱锁'), findsOneWidget);
    expect(find.text('USB 电源'), findsOneWidget);
  });

  testWidgets('umbrella exposes safety controls', (tester) async {
    await pumpDetail(tester, 'umbrella_sun_01');

    expect(find.text('开伞'), findsOneWidget);
    expect(find.text('收伞'), findsOneWidget);
    expect(find.text('防风阈值'), findsOneWidget);
  });

  testWidgets('platform exposes leveling and emergency stop', (tester) async {
    await pumpDetail(tester, 'platform_lock_01');

    expect(find.text('一键调平'), findsOneWidget);
    expect(find.text('四腿微调'), findsOneWidget);
    expect(find.text('紧急停止'), findsOneWidget);
  });
}
