import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zhiyou_app/shared/widgets/ink_app_widgets.dart';

void main() {
  testWidgets('brand renders smart fishing identity', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: InkBrand())),
          );
        },
      ),
    );

    expect(find.text('江湖钓客'), findsOneWidget);
    expect(find.text('智能设备'), findsOneWidget);
    expect(find.text('AI 出钓决策'), findsOneWidget);
  });
}
