import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/features/devices/application/device_center_controller.dart';
import 'package:zhiyou_app/features/devices/data/device_center_demo_data.dart';
import 'package:zhiyou_app/features/devices/view/device_center_screen.dart';

void main() {
  testWidgets('device center exposes health summary filters and core devices', (
    tester,
  ) async {
    final devices = demoDeviceCenterDevices;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) {
          return MaterialApp(
            home: DeviceCenterBody(
              state: DeviceCenterState(
                devices: devices,
                source: 'demo',
                selectedDeviceId: devices.first.id,
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('设备中心'), findsOneWidget);
    expect(find.text('全部设备'), findsWidgets);
    expect(find.text('只看异常'), findsOneWidget);
    expect(find.textContaining('智能钓箱'), findsWidgets);
    expect(find.textContaining('智能钓伞'), findsWidgets);
    expect(find.textContaining('智能钓台'), findsWidgets);
    expect(find.text('场景联动'), findsOneWidget);
  });
}
