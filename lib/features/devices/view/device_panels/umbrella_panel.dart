import 'package:flutter/material.dart';

import '../../../../shared/widgets/ink_app_widgets.dart';
import '../../application/device_center_controller.dart';
import '../../data/device_center_models.dart';
import '../widgets/device_components.dart';

class UmbrellaPanel extends StatefulWidget {
  const UmbrellaPanel({
    super.key,
    required this.bundle,
    required this.controlState,
    required this.onCommand,
  });

  final DeviceDetailBundle bundle;
  final DeviceControlState controlState;
  final DeviceCommandHandler onCommand;

  @override
  State<UmbrellaPanel> createState() => _UmbrellaPanelState();
}

class _UmbrellaPanelState extends State<UmbrellaPanel> {
  bool _open = true;
  double _tilt = 15;
  double _threshold = 5;
  bool _sunTracking = true;
  bool _rainResponse = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.controlState.localDeviceState;
    _open = state['umbrella_open'] as bool? ?? _open;
    _tilt = (state['tilt_angle'] as num?)?.toDouble() ?? _tilt;
    _threshold = (state['wind_threshold'] as num?)?.toDouble() ?? _threshold;
    return Column(
      children: [
        const DeviceSurface(
          child: Row(
            children: [
              Expanded(
                child: DeviceMetric(
                  label: '风力',
                  value: '3 级',
                  icon: Icons.air_rounded,
                  color: InkPalette.lake,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DeviceMetric(
                  label: 'UV',
                  value: '中等',
                  icon: Icons.wb_sunny_rounded,
                  color: InkPalette.reed,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DeviceMetric(
                  label: '降雨',
                  value: '10%',
                  icon: Icons.water_drop_rounded,
                  color: InkPalette.lake,
                ),
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
                icon: Icons.umbrella_rounded,
                title: '开合控制',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _open
                          ? null
                          : () {
                              setState(() => _open = true);
                              widget.onCommand('open_umbrella', {});
                            },
                      icon: const Icon(Icons.umbrella_rounded),
                      label: const Text('开伞'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !_open
                          ? null
                          : () async {
                              final confirmed = await _confirmClose(context);
                              if (!confirmed) return;
                              setState(() => _open = false);
                              await widget.onCommand(
                                'close_umbrella',
                                {},
                                confirmed: true,
                              );
                            },
                      icon: const Icon(Icons.vertical_align_bottom_rounded),
                      label: const Text('收伞'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '倾斜角度调节',
                      style: TextStyle(
                        color: InkPalette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_tilt.round()}°',
                    style: const TextStyle(
                      color: InkPalette.pine,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _tilt,
                min: -45,
                max: 45,
                divisions: 6,
                onChanged: (value) => setState(() => _tilt = value),
                onChangeEnd: (value) =>
                    widget.onCommand('set_tilt', {'angle': value.round()}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '防风阈值',
                      style: TextStyle(
                        color: InkPalette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_threshold.round()} 级',
                    style: const TextStyle(
                      color: InkPalette.pine,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _threshold,
                min: 3,
                max: 8,
                divisions: 5,
                onChanged: (value) => setState(() => _threshold = value),
                onChangeEnd: (value) => widget.onCommand('set_wind_threshold', {
                  'level': value.round(),
                }),
              ),
              const Text(
                '超过阈值将自动收伞',
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
        DeviceSurface(
          child: Column(
            children: [
              const DeviceSectionTitle(
                icon: Icons.auto_awesome_rounded,
                title: '智能模式',
              ),
              const SizedBox(height: 10),
              DeviceToggleRow(
                icon: Icons.wb_sunny_rounded,
                title: '太阳跟随模式',
                subtitle: '随太阳方位自动调节角度',
                value: _sunTracking,
                onChanged: (value) {
                  setState(() => _sunTracking = value);
                  widget.onCommand('set_automation', {'sun_tracking': value});
                },
              ),
              const Divider(height: 24),
              DeviceToggleRow(
                icon: Icons.water_drop_rounded,
                title: '降雨响应',
                subtitle: '降雨概率超过 60% 自动收伞',
                value: _rainResponse,
                onChanged: (value) {
                  setState(() => _rainResponse = value);
                  widget.onCommand('set_automation', {'rain_response': value});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DeviceSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeviceSectionTitle(icon: Icons.history_rounded, title: '最近事件'),
              SizedBox(height: 10),
              _EventRow(time: '12:28', title: '风力升至 5 级，自动收伞'),
              _EventRow(time: '11:05', title: '手动开伞'),
              _EventRow(time: '08:12', title: '太阳跟随模式已开启'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.time, required this.title});

  final String time;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 9, color: InkPalette.pine),
          const SizedBox(width: 9),
          SizedBox(
            width: 46,
            child: Text(
              time,
              style: const TextStyle(
                color: InkPalette.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: InkPalette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmClose(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认收伞？'),
          content: const Text('收伞会改变设备机械状态，请确认周围无人且钓具已经避让。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认收伞'),
            ),
          ],
        ),
      ) ??
      false;
}
