import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../../home/data/device_models.dart';
import '../application/device_center_controller.dart';
import 'widgets/device_components.dart';
import 'widgets/device_shell.dart';

class DeviceCenterScreen extends ConsumerWidget {
  const DeviceCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceCenterProvider);
    return state.when(
      loading: () => DevicePageShell(
        title: context.l10n.deviceCenter,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => DevicePageShell(
        title: context.l10n.deviceCenter,
        child: AppErrorView(
          title: context.l10n.deviceLoadFailed,
          message: error.toString(),
          actionLabel: context.l10n.actionRetry,
          onAction: () => ref.invalidate(deviceCenterProvider),
        ),
      ),
      data: (value) => DeviceCenterBody(
        state: value,
        onFilter: ref.read(deviceCenterProvider.notifier).setFilter,
        onSelect: ref.read(deviceCenterProvider.notifier).selectDevice,
        onOpenDevice: (deviceId) =>
            context.push(AppRouteNames.deviceDetailPath(deviceId)),
        onAddDevice: () => context.push(AppRouteNames.deviceAdd),
        onScenes: () => context.push(AppRouteNames.deviceScenes),
        onAlerts: () => context.push(AppRouteNames.deviceAlerts),
        onRefresh: ref.read(deviceCenterProvider.notifier).refresh,
      ),
    );
  }
}

class DeviceCenterBody extends StatelessWidget {
  const DeviceCenterBody({
    super.key,
    required this.state,
    this.onFilter,
    this.onSelect,
    this.onOpenDevice,
    this.onAddDevice,
    this.onScenes,
    this.onAlerts,
    this.onRefresh,
  });

  final DeviceCenterState state;
  final ValueChanged<String>? onFilter;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onOpenDevice;
  final VoidCallback? onAddDevice;
  final VoidCallback? onScenes;
  final VoidCallback? onAlerts;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final devices = state.devices;
    final online = devices.where((item) => item.isOnline).length;
    final warning = devices
        .where((item) => item.alerts.isNotEmpty || item.isLowBattery)
        .length;
    return DevicePageShell(
      title: context.l10n.deviceCenter,
      showBack: true,
      actions: [
        IconButton(
          tooltip: context.l10n.actionAddDevice,
          onPressed: onAddDevice,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mode = DeviceResponsiveMode.fromWidth(constraints.maxWidth);
          final overview = _OverviewPane(
            devices: devices,
            online: online,
            warning: warning,
            source: state.source,
            onAlerts: onAlerts,
            onScenes: onScenes,
            onAddDevice: onAddDevice,
          );
          final list = _DeviceListPane(
            state: state,
            onFilter: onFilter,
            onSelect: onSelect,
            onOpenDevice: onOpenDevice,
            onRefresh: onRefresh,
          );
          if (mode == DeviceResponsiveMode.phone) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [overview, const SizedBox(height: 12), list],
            );
          }
          final selected = devices.where(
            (item) => item.id == state.selectedDeviceId,
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: mode == DeviceResponsiveMode.desktop ? 270 : 235,
                child: SingleChildScrollView(child: overview),
              ),
              const SizedBox(width: 14),
              Expanded(child: SingleChildScrollView(child: list)),
              if (mode == DeviceResponsiveMode.desktop) ...[
                const SizedBox(width: 14),
                SizedBox(
                  width: 310,
                  child: _SelectedDevicePreview(
                    device: selected.isEmpty ? null : selected.first,
                    onOpenDevice: onOpenDevice,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({
    required this.devices,
    required this.online,
    required this.warning,
    required this.source,
    this.onAlerts,
    this.onScenes,
    this.onAddDevice,
  });

  final List<Device> devices;
  final int online;
  final int warning;
  final String source;
  final VoidCallback? onAlerts;
  final VoidCallback? onScenes;
  final VoidCallback? onAddDevice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DeviceSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeviceSectionTitle(
                icon: Icons.health_and_safety_rounded,
                title: context.l10n.deviceHealth,
              ),
              const SizedBox(height: 14),
              Text(
                warning == 0
                    ? context.l10n.deviceStable
                    : context.l10n.devicePending(warning),
                style: TextStyle(
                  color: warning == 0 ? InkPalette.pine : InkPalette.reed,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$online/${devices.length} 台在线 · ${source == 'api' ? '实时 API' : '演示数据'}',
                style: const TextStyle(
                  color: InkPalette.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: devices.isEmpty ? 0 : online / devices.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DeviceSurface(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: Text(context.l10n.deviceScenes),
                subtitle: const Text('开钓 · 夜钓 · 收竿'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onScenes,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded),
                title: const Text('告警中心'),
                subtitle: Text(warning == 0 ? '暂无待处理告警' : '$warning 项待处理'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onAlerts,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_link_rounded),
                title: const Text('新增设备'),
                subtitle: const Text('扫码 · 蓝牙 · 手动选择'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onAddDevice,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceListPane extends StatelessWidget {
  const _DeviceListPane({
    required this.state,
    this.onFilter,
    this.onSelect,
    this.onOpenDevice,
    this.onRefresh,
  });

  final DeviceCenterState state;
  final ValueChanged<String>? onFilter;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onOpenDevice;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return DeviceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.deviceAll,
                  style: const TextStyle(
                    color: InkPalette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: '刷新设备',
                onPressed: onRefresh == null ? null : () => onRefresh!(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(context.l10n.deviceAll),
                selected: state.filter == 'all',
                onSelected: (_) => onFilter?.call('all'),
              ),
              ChoiceChip(
                label: Text(context.l10n.deviceOnline),
                selected: state.filter == 'online',
                onSelected: (_) => onFilter?.call('online'),
              ),
              ChoiceChip(
                label: Text(context.l10n.deviceAlertsOnly),
                selected: state.filter == 'alerts',
                onSelected: (_) => onFilter?.call('alerts'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final device in state.visibleDevices) ...[
            _DeviceRow(
              device: device,
              selected: state.selectedDeviceId == device.id,
              onTap: () {
                onSelect?.call(device.id);
                onOpenDevice?.call(device.id);
              },
            ),
            if (device != state.visibleDevices.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final Device device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = deviceTypeColor(device.type);
    final telemetry = device.telemetry.isEmpty ? null : device.telemetry.first;
    return Material(
      color: selected ? color.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(deviceTypeIcon(device.type), color: color),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${telemetry?.label ?? device.sceneRole} ${telemetry?.value ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              device.isOnline ? '在线' : '待机',
              style: TextStyle(
                color: device.isOnline ? InkPalette.pine : InkPalette.faint,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${device.batteryLevel}%',
              style: const TextStyle(
                color: InkPalette.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SelectedDevicePreview extends StatelessWidget {
  const _SelectedDevicePreview({required this.device, this.onOpenDevice});

  final Device? device;
  final ValueChanged<String>? onOpenDevice;

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return const DeviceSurface(child: Text('选择设备查看实时详情'));
    }
    final item = device!;
    return DeviceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            deviceTypeIcon(item.type),
            color: deviceTypeColor(item.type),
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(
              color: InkPalette.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final telemetry in item.telemetry.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(telemetry.label)),
                  Text(
                    telemetry.value,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onOpenDevice?.call(item.id),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('打开控制台'),
            ),
          ),
        ],
      ),
    );
  }
}
