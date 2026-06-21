import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../application/device_center_controller.dart';
import 'widgets/device_components.dart';
import 'widgets/device_shell.dart';

class DeviceAlertsScreen extends ConsumerWidget {
  const DeviceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(deviceCenterProvider);
    return DevicePageShell(
      title: '告警中心',
      child: center.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (state) {
          final alerts = [
            for (final device in state.devices)
              for (final alert in device.alerts) (device, alert),
          ];
          if (alerts.isEmpty) {
            return const DeviceSurface(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: InkPalette.moss,
                        size: 52,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '当前没有设备告警',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = alerts[index];
              return DeviceSurface(
                borderColor: InkPalette.reed.withValues(alpha: 0.25),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: InkPalette.reed,
                  ),
                  title: Text(
                    entry.$2.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('${entry.$1.name} · ${entry.$2.message}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      context.push(AppRouteNames.deviceDetailPath(entry.$1.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
