import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/device_center_models.dart';
import '../data/device_center_repository.dart';
import 'widgets/device_components.dart';
import 'widgets/device_shell.dart';

class DeviceCommandScreen extends ConsumerWidget {
  const DeviceCommandScreen({super.key, required this.commandId});

  final String commandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DevicePageShell(
      title: '命令结果',
      child: FutureBuilder<DeviceCommandReceipt>(
        future: ref
            .read(deviceCenterRepositoryProvider)
            .fetchCommand(commandId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return DeviceSurface(
              child: Text(snapshot.error?.toString() ?? '命令不存在'),
            );
          }
          final receipt = snapshot.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DeviceSurface(
                child: Column(
                  children: [
                    Icon(
                      receipt.succeeded
                          ? Icons.check_circle_rounded
                          : receipt.awaitingConfirmation
                          ? Icons.verified_user_rounded
                          : Icons.error_rounded,
                      color: receipt.succeeded
                          ? InkPalette.pine
                          : InkPalette.reed,
                      size: 58,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      receipt.succeeded
                          ? '设备执行成功'
                          : receipt.awaitingConfirmation
                          ? '等待确认'
                          : '设备执行失败',
                      style: const TextStyle(
                        color: InkPalette.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      receipt.commandId,
                      style: const TextStyle(
                        color: InkPalette.muted,
                        fontWeight: FontWeight.w700,
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
                      icon: Icons.timeline_rounded,
                      title: '执行时间线',
                    ),
                    const SizedBox(height: 10),
                    for (final item in receipt.timeline)
                      _TimelineRow(item: item),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item});

  final DeviceCommandTimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, color: InkPalette.pine, size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(item.status),
                  style: const TextStyle(
                    color: InkPalette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: InkPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'queued' => '进入队列',
  'sent' => '已发送',
  'acknowledged' => '设备确认',
  'succeeded' => '执行成功',
  'awaiting_confirmation' => '等待确认',
  _ => status,
};
