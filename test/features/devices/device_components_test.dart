import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/features/devices/view/widgets/device_shell.dart';

void main() {
  test('responsive device shell selects phone tablet and desktop modes', () {
    expect(DeviceResponsiveMode.fromWidth(390), DeviceResponsiveMode.phone);
    expect(DeviceResponsiveMode.fromWidth(768), DeviceResponsiveMode.tablet);
    expect(DeviceResponsiveMode.fromWidth(1440), DeviceResponsiveMode.desktop);
  });
}
