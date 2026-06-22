import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/shared/widgets/ink_app_widgets.dart';

void main() {
  testWidgets('wide pages keep readable centered content width', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: InkPage(
          child: SizedBox.expand(key: ValueKey('page-content')),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const ValueKey('page-content')));
    expect(size.width, lessThanOrEqualTo(1480));
  });
}
