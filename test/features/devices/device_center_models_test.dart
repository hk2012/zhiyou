import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/features/devices/data/device_center_models.dart';

void main() {
  test('parses device capabilities and danger level', () {
    final result = DeviceCapabilitySet.fromJson({
      'device_id': 'umbrella_sun_01',
      'device_type': 'smart_umbrella',
      'capabilities': [
        {
          'key': 'close_umbrella',
          'label': '收伞',
          'kind': 'command',
          'value_type': 'action',
          'danger_level': 'confirm',
        },
      ],
    });

    expect(result.deviceId, 'umbrella_sun_01');
    expect(result.capabilities.single.requiresConfirmation, isTrue);
  });

  test('parses command timeline and terminal state', () {
    final receipt = DeviceCommandReceipt.fromJson({
      'command_id': 'cmd_demo',
      'device_id': 'box_cool_01',
      'command': 'set_light',
      'status': 'succeeded',
      'dangerous': false,
      'parameters': {'enabled': true},
      'result': {'enabled': true},
      'timeline': [
        {'status': 'queued', 'at': '2026-06-21T08:00:00Z', 'message': '已排队'},
        {'status': 'succeeded', 'at': '2026-06-21T08:00:01Z', 'message': '完成'},
      ],
      'failure_reason': '',
      'created_at': '2026-06-21T08:00:00Z',
      'updated_at': '2026-06-21T08:00:01Z',
    });

    expect(receipt.isTerminal, isTrue);
    expect(receipt.succeeded, isTrue);
    expect(receipt.timeline, hasLength(2));
  });

  test('parses automation scene actions', () {
    final scene = DeviceAutomationScene.fromJson({
      'id': 'scene_pack',
      'name': '收竿',
      'description': '安全关闭设备',
      'enabled': true,
      'actions': [
        {
          'device_id': 'umbrella_sun_01',
          'command': 'close_umbrella',
          'parameters': {},
          'confirmed': true,
        },
      ],
    });

    expect(scene.actions.single.confirmed, isTrue);
    expect(scene.name, '收竿');
  });
}
