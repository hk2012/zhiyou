import 'package:flutter/material.dart';

import '../../../../shared/widgets/ink_app_widgets.dart';
import '../../application/device_center_controller.dart';
import '../../data/device_center_models.dart';
import '../widgets/device_charts.dart';
import '../widgets/device_components.dart';

class TackleBoxPanel extends StatefulWidget {
  const TackleBoxPanel({
    super.key,
    required this.bundle,
    required this.controlState,
    required this.onCommand,
  });

  final DeviceDetailBundle bundle;
  final DeviceControlState controlState;
  final DeviceCommandHandler onCommand;

  @override
  State<TackleBoxPanel> createState() => _TackleBoxPanelState();
}

class _TackleBoxPanelState extends State<TackleBoxPanel> {
  double _temperature = 4;
  String _mode = 'medium';
  bool _locked = false;
  bool _light = true;
  bool _usb = true;

  @override
  Widget build(BuildContext context) {
    final local = widget.controlState.localDeviceState;
    _locked = local['locked'] as bool? ?? _locked;
    _light = local['light_enabled'] as bool? ?? _light;
    _usb = local['usb_power_enabled'] as bool? ?? _usb;
    return Column(
      children: [
        DeviceSurface(
          child: Column(
            children: [
              const DeviceSectionTitle(
                icon: Icons.thermostat_rounded,
                title: '温度设定',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final temperature = _TemperatureControl(
                    temperature: _temperature,
                    onChanged: (value) {
                      setState(() => _temperature = value);
                      widget.onCommand('set_temperature', {
                        'temperature': value.round(),
                      });
                    },
                  );
                  final modes = _CoolingModes(
                    selected: _mode,
                    onChanged: (mode) {
                      setState(() => _mode = mode);
                      widget.onCommand('set_cooling_mode', {'mode': mode});
                    },
                  );
                  if (compact) {
                    return Column(
                      children: [temperature, const Divider(height: 30), modes],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: temperature),
                      const SizedBox(
                        height: 118,
                        child: VerticalDivider(width: 30),
                      ),
                      Expanded(child: modes),
                    ],
                  );
                },
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
                title: '箱锁',
                subtitle: _locked ? '已锁定' : '已解锁 · 锁箱需要确认',
                value: _locked,
                onChanged: (value) async {
                  if (value) {
                    final confirmed = await _confirm(
                      context,
                      '确认锁箱？',
                      '锁箱后需要再次操作才能开启。',
                    );
                    if (!confirmed) return;
                  }
                  setState(() => _locked = value);
                  await widget.onCommand('set_lock', {
                    'locked': value,
                  }, confirmed: value);
                },
              ),
              const Divider(height: 24),
              DeviceToggleRow(
                icon: Icons.lightbulb_rounded,
                title: '照明',
                subtitle: _light ? '已开启' : '已关闭',
                value: _light,
                onChanged: (value) {
                  setState(() => _light = value);
                  widget.onCommand('set_light', {'enabled': value});
                },
              ),
              const Divider(height: 24),
              DeviceToggleRow(
                icon: Icons.usb_rounded,
                title: 'USB 电源',
                subtitle: _usb ? '已开启' : '已关闭',
                value: _usb,
                onChanged: (value) {
                  setState(() => _usb = value);
                  widget.onCommand('set_usb_power', {'enabled': value});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DeviceSurface(
          child: Column(
            children: [
              DeviceSectionTitle(
                icon: Icons.inventory_2_rounded,
                title: '保鲜记录',
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DeviceMetric(
                      label: '存放重量',
                      value: '2.5 kg',
                      icon: Icons.scale_rounded,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DeviceMetric(
                      label: '保鲜时长',
                      value: '18 小时',
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DeviceMetric(
                      label: '保鲜评分',
                      value: '98%',
                      icon: Icons.verified_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DeviceSurface(
          child: Column(
            children: [
              DeviceSectionTitle(
                icon: Icons.show_chart_rounded,
                title: '24 小时温度趋势',
              ),
              SizedBox(height: 8),
              DeviceTrendChart(
                label: '箱内温度 (°C)',
                values: [
                  4,
                  3.6,
                  4.1,
                  3.8,
                  4,
                  3.4,
                  3.6,
                  3.2,
                  3.5,
                  3.8,
                  4.2,
                  3.9,
                  4,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemperatureControl extends StatelessWidget {
  const _TemperatureControl({
    required this.temperature,
    required this.onChanged,
  });

  final double temperature;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${temperature.round()}°C',
          style: const TextStyle(
            color: InkPalette.pine,
            fontSize: 42,
            fontWeight: FontWeight.w900,
          ),
        ),
        Slider(
          value: temperature,
          min: 0,
          max: 20,
          divisions: 20,
          label: '${temperature.round()}°C',
          onChanged: (value) => onChanged(value),
        ),
        const Text(
          '范围 0°C - 20°C',
          style: TextStyle(
            color: InkPalette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CoolingModes extends StatelessWidget {
  const _CoolingModes({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '制冷模式',
          style: TextStyle(color: InkPalette.text, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'low', label: Text('低')),
            ButtonSegment(value: 'medium', label: Text('中')),
            ButtonSegment(value: 'high', label: Text('高')),
          ],
          selected: {selected},
          onSelectionChanged: (values) => onChanged(values.first),
        ),
      ],
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
