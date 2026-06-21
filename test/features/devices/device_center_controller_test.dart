import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/features/devices/application/device_center_controller.dart';
import 'package:zhiyou_app/features/devices/data/device_center_models.dart';

void main() {
  test(
    'command state keeps latest receipt and updates selected device state',
    () {
      const initial = DeviceControlState();
      final receipt = DeviceCommandReceipt.fromJson({
        'command_id': 'cmd_1',
        'device_id': 'box_cool_01',
        'command': 'set_light',
        'status': 'succeeded',
        'dangerous': false,
        'parameters': {'enabled': true},
        'result': {'enabled': true},
        'timeline': const [],
        'failure_reason': '',
        'created_at': '2026-06-21T08:00:00Z',
        'updated_at': '2026-06-21T08:00:01Z',
      });

      final next = initial.withReceipt(receipt);

      expect(next.latestReceipt?.commandId, 'cmd_1');
      expect(next.localDeviceState['light_enabled'], isTrue);
      expect(next.isSubmitting, isFalse);
    },
  );

  test('awaiting confirmation is exposed as a pending dangerous action', () {
    const initial = DeviceControlState();
    final receipt = DeviceCommandReceipt.fromJson({
      'command_id': 'cmd_2',
      'device_id': 'umbrella_sun_01',
      'command': 'close_umbrella',
      'status': 'awaiting_confirmation',
      'dangerous': true,
      'parameters': const {},
      'result': const {},
      'timeline': const [],
      'failure_reason': '',
      'created_at': '2026-06-21T08:00:00Z',
      'updated_at': '2026-06-21T08:00:00Z',
    });

    final next = initial.withReceipt(receipt);

    expect(next.needsConfirmation, isTrue);
    expect(next.localDeviceState, isEmpty);
  });
}
