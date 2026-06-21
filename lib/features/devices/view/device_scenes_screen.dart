import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../application/device_center_controller.dart';
import '../data/device_center_models.dart';
import '../data/device_center_repository.dart';
import 'widgets/device_components.dart';
import 'widgets/device_shell.dart';

class DeviceScenesScreen extends ConsumerWidget {
  const DeviceScenesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(deviceScenesProvider);
    return DevicePageShell(
      title: '场景联动',
      child: scenes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (items) => ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _SceneCard(
            scene: items[index],
            onExecute: () async {
              try {
                final result = await ref
                    .read(deviceCenterRepositoryProvider)
                    .executeScene(items[index].id);
                if (context.mounted && result.commands.isNotEmpty) {
                  context.push(
                    AppRouteNames.deviceCommandPath(
                      result.commands.last.commandId,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('场景执行失败，请检查设备连接')),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene, required this.onExecute});

  final DeviceAutomationScene scene;
  final VoidCallback onExecute;

  @override
  Widget build(BuildContext context) {
    final icon = switch (scene.name) {
      '开钓' => Icons.play_circle_rounded,
      '夜钓' => Icons.dark_mode_rounded,
      '收竿' => Icons.inventory_2_rounded,
      _ => Icons.auto_awesome_rounded,
    };
    return DeviceSurface(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: InkPalette.pine.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: InkPalette.pine, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.name,
                  style: const TextStyle(
                    color: InkPalette.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scene.description,
                  style: const TextStyle(
                    color: InkPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${scene.actions.length} 个设备动作',
                  style: const TextStyle(
                    color: InkPalette.pine,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: scene.actions.isEmpty ? null : onExecute,
            child: const Text('执行'),
          ),
        ],
      ),
    );
  }
}
