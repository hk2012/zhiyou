import 'package:flutter/material.dart';

import '../../../../shared/widgets/ink_app_widgets.dart';
import '../../application/device_center_controller.dart';
import '../../data/device_center_models.dart';
import '../widgets/device_components.dart';

class PlatformPanel extends StatefulWidget {
  const PlatformPanel({
    super.key,
    required this.bundle,
    required this.controlState,
    required this.onCommand,
  });

  final DeviceDetailBundle bundle;
  final DeviceControlState controlState;
  final DeviceCommandHandler onCommand;

  @override
  State<PlatformPanel> createState() => _PlatformPanelState();
}

class _PlatformPanelState extends State<PlatformPanel> {
  final Map<String, int> _legs = {
    'front_left': 2,
    'front_right': -1,
    'rear_left': -2,
    'rear_right': 1,
  };
  bool _safetyLock = false;

  @override
  Widget build(BuildContext context) {
    final tilt =
        (widget.controlState.localDeviceState['tilt_angle'] as num?)
            ?.toDouble() ??
        2;
    return Column(
      children: [
        DeviceSurface(
          child: Column(
            children: [
              const DeviceSectionTitle(
                icon: Icons.balance_rounded,
                title: '平台水平',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '当前倾斜',
                          style: TextStyle(
                            color: InkPalette.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${tilt.round()}°',
                          style: const TextStyle(
                            color: InkPalette.pine,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const DeviceStatusPill(
                          icon: Icons.north_rounded,
                          label: '前高',
                          color: InkPalette.pine,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => widget.onCommand('auto_level', {}),
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: const Text('一键调平'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DeviceSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DeviceSectionTitle(
                icon: Icons.settings_input_component_rounded,
                title: '四腿微调',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 620 ? 2 : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    childAspectRatio: columns == 1 ? 4.4 : 3.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _LegControl(
                        label: '前左',
                        legKey: 'front_left',
                        values: _legs,
                        onChanged: _updateLeg,
                      ),
                      _LegControl(
                        label: '前右',
                        legKey: 'front_right',
                        values: _legs,
                        onChanged: _updateLeg,
                      ),
                      _LegControl(
                        label: '后左',
                        legKey: 'rear_left',
                        values: _legs,
                        onChanged: _updateLeg,
                      ),
                      _LegControl(
                        label: '后右',
                        legKey: 'rear_right',
                        values: _legs,
                        onChanged: _updateLeg,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                '单位 mm · 调节范围 -30 至 30 mm',
                style: TextStyle(
                  color: InkPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DeviceSurface(
          child: Row(
            children: [
              Expanded(
                child: DeviceMetric(
                  label: '总负载',
                  value: '18.6 kg',
                  icon: Icons.donut_large_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: DeviceMetric(
                  label: '稳定性',
                  value: '稳定',
                  icon: Icons.verified_user_rounded,
                  color: InkPalette.moss,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DeviceSurface(
          child: Column(
            children: [
              DeviceToggleRow(
                icon: Icons.lock_rounded,
                title: '安全锁',
                subtitle: '锁定后禁止所有调节操作',
                value: _safetyLock,
                onChanged: (value) async {
                  if (value) {
                    final ok = await _confirm(
                      context,
                      '启用安全锁？',
                      '启用后将禁止支腿调整，直到再次解锁。',
                    );
                    if (!ok) return;
                  }
                  setState(() => _safetyLock = value);
                  await widget.onCommand('set_safety_lock', {
                    'enabled': value,
                  }, confirmed: value);
                },
              ),
              const Divider(height: 26),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: InkPalette.cinnabar.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: InkPalette.cinnabar.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stop_circle_rounded,
                      color: InkPalette.cinnabar,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '紧急停止',
                            style: TextStyle(
                              color: InkPalette.cinnabar,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '立即停止并锁定所有执行器',
                            style: TextStyle(
                              color: InkPalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final ok = await _confirm(
                          context,
                          '执行紧急停止？',
                          '该操作会立即锁定所有执行器，需要重新校准后才能恢复。',
                        );
                        if (!ok) return;
                        await widget.onCommand(
                          'emergency_stop',
                          {},
                          confirmed: true,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: InkPalette.cinnabar,
                        side: const BorderSide(color: InkPalette.cinnabar),
                      ),
                      child: const Text('立即停止'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateLeg(String key, int value) {
    setState(() => _legs[key] = value.clamp(-30, 30));
    widget.onCommand('adjust_leg', {'leg': key, 'offset_mm': _legs[key]});
  }
}

class _LegControl extends StatelessWidget {
  const _LegControl({
    required this.label,
    required this.legKey,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String legKey;
  final Map<String, int> values;
  final void Function(String key, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final value = values[legKey] ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: InkPalette.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InkPalette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: InkPalette.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: '$label 降低',
            onPressed: () => onChanged(legKey, value - 1),
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: InkPalette.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: '$label 升高',
            onPressed: () => onChanged(legKey, value + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        ),
      ) ??
      false;
}
