import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../application/device_center_controller.dart';
import '../data/device_center_repository.dart';
import 'widgets/device_components.dart';
import 'widgets/device_shell.dart';

class DeviceBindingScreen extends ConsumerStatefulWidget {
  const DeviceBindingScreen({super.key});

  @override
  ConsumerState<DeviceBindingScreen> createState() =>
      _DeviceBindingScreenState();
}

class _DeviceBindingScreenState extends ConsumerState<DeviceBindingScreen> {
  String _type = 'night_light';
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    return DevicePageShell(
      title: '新增设备',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DeviceSurface(
            child: Column(
              children: [
                const Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 56,
                  color: InkPalette.pine,
                ),
                const SizedBox(height: 12),
                const Text(
                  '发现附近设备',
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '支持扫码、蓝牙发现和手动选择型号',
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _searching ? null : _discover,
                    icon: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.radar_rounded),
                    label: Text(_searching ? '正在搜索' : '开始搜索'),
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
                  icon: Icons.category_rounded,
                  title: '手动选择型号',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  items: const [
                    DropdownMenuItem(
                      value: 'night_light',
                      child: Text('智能夜钓灯'),
                    ),
                    DropdownMenuItem(value: 'fish_finder', child: Text('探鱼器')),
                    DropdownMenuItem(value: 'sensor', child: Text('环境传感器')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _bind,
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('绑定演示设备'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _discover() async {
    setState(() => _searching = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _searching = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('发现 1 台可绑定设备')));
  }

  Future<void> _bind() async {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
      7,
    );
    final labels = {
      'night_light': ('智能夜钓灯 L-01', '夜间照明'),
      'fish_finder': ('便携探鱼器 FF-01', '鱼层扫描'),
      'sensor': ('环境传感器 S-01', '环境监测'),
    };
    final value = labels[_type]!;
    try {
      await ref
          .read(deviceCenterRepositoryProvider)
          .bindDemoDevice(
            deviceUid: '${_type}_$suffix',
            name: value.$1,
            deviceType: _type,
            sceneRole: value.$2,
          );
      ref.invalidate(deviceCenterProvider);
      if (mounted) {
        Navigator.popUntil(
          context,
          (route) =>
              route.settings.name == AppRouteNames.devices || route.isFirst,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('绑定失败，请确认后端服务已启动')));
      }
    }
  }
}
