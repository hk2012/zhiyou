import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/app_domain_models.dart';
import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../application/device_center_controller.dart';
import '../data/device_center_models.dart';
import '../data/device_center_repository.dart';
import 'device_panels/platform_panel.dart';
import 'device_panels/tackle_box_panel.dart';
import 'device_panels/umbrella_panel.dart';
import 'widgets/device_components.dart';
import 'widgets/device_shell.dart';

class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(deviceDetailProvider(deviceId));
    return detail.when(
      loading: () => const DevicePageShell(
        title: '设备详情',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => DevicePageShell(
        title: '设备详情',
        child: AppErrorView(
          title: '设备详情加载失败',
          message: error.toString(),
          actionLabel: '重试',
          onAction: () => ref.invalidate(deviceDetailProvider(deviceId)),
        ),
      ),
      data: (bundle) => DeviceDetailBody(
        bundle: bundle,
        controlState: ref.watch(deviceControlProvider(deviceId)),
        onCommand: (command, parameters, {bool confirmed = false}) async {
          final receipt = await ref
              .read(deviceControlProvider(deviceId).notifier)
              .issue(command, parameters: parameters, confirmed: confirmed);
          if (receipt != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  receipt.awaitingConfirmation
                      ? '该操作需要再次确认'
                      : '设备已执行 · ${receipt.commandId}',
                ),
              ),
            );
          }
        },
        onCommandDetails: (commandId) {
          context.push(AppRouteNames.deviceCommandPath(commandId));
        },
        onFirmwareUpgrade: () async {
          final confirmed = await _confirmFirmware(context);
          if (!confirmed) return;
          final receipt = await ref
              .read(deviceCenterRepositoryProvider)
              .startFirmwareUpgrade(deviceId, confirmed: true);
          ref
              .read(deviceControlProvider(deviceId).notifier)
              .issue(
                'firmware_upgrade',
                parameters: {'target_version': bundle.firmware.latestVersion},
                confirmed: true,
              );
          if (context.mounted) {
            context.push(AppRouteNames.deviceCommandPath(receipt.commandId));
          }
        },
      ),
    );
  }
}

class DeviceDetailBody extends StatefulWidget {
  const DeviceDetailBody({
    super.key,
    required this.bundle,
    this.controlState = const DeviceControlState(),
    this.onCommand,
    this.onCommandDetails,
    this.onFirmwareUpgrade,
  });

  final DeviceDetailBundle bundle;
  final DeviceControlState controlState;
  final DeviceCommandHandler? onCommand;
  final ValueChanged<String>? onCommandDetails;
  final VoidCallback? onFirmwareUpgrade;

  @override
  State<DeviceDetailBody> createState() => _DeviceDetailBodyState();
}

class _DeviceDetailBodyState extends State<DeviceDetailBody> {
  DeviceDetailTab _selectedTab = DeviceDetailTab.status;

  Future<void> _command(
    String command,
    Map<String, dynamic> parameters, {
    bool confirmed = false,
  }) async {
    await widget.onCommand?.call(command, parameters, confirmed: confirmed);
  }

  @override
  Widget build(BuildContext context) {
    final bundle = widget.bundle;
    final receipt = widget.controlState.latestReceipt;
    return DevicePageShell(
      title: bundle.device.type.label,
      actions: [
        IconButton(
          tooltip: '更多设备操作',
          onPressed: () => _showDeviceMenu(context),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DeviceHeader(device: bundle.device, source: bundle.source),
          const SizedBox(height: 12),
          _HeroMetrics(bundle: bundle),
          const SizedBox(height: 12),
          DeviceTabBar(
            selected: _selectedTab,
            onSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: 12),
          if (widget.controlState.isSubmitting ||
              widget.controlState.latestReceipt != null ||
              widget.controlState.errorMessage.isNotEmpty) ...[
            DeviceCommandBanner(
              state: widget.controlState,
              onDetails: receipt == null
                  ? null
                  : () => widget.onCommandDetails?.call(receipt.commandId),
            ),
            const SizedBox(height: 12),
          ],
          _devicePanel(bundle),
          const SizedBox(height: 12),
          _tabContent(bundle),
          const SizedBox(height: 12),
          _MaintenanceSummary(
            bundle: bundle,
            onFirmwareUpgrade: widget.onFirmwareUpgrade,
            onCalibrate: () => _command(
              'calibrate',
              {},
              confirmed: bundle.device.type == DomainDeviceType.smartPlatform,
            ),
          ),
        ],
      ),
    );
  }

  Widget _devicePanel(DeviceDetailBundle bundle) {
    return switch (bundle.device.type) {
      DomainDeviceType.smartTackleBox => TackleBoxPanel(
        bundle: bundle,
        controlState: widget.controlState,
        onCommand: _command,
      ),
      DomainDeviceType.smartUmbrella => UmbrellaPanel(
        bundle: bundle,
        controlState: widget.controlState,
        onCommand: _command,
      ),
      DomainDeviceType.smartPlatform => PlatformPanel(
        bundle: bundle,
        controlState: widget.controlState,
        onCommand: _command,
      ),
      _ => _GenericDevicePanel(bundle: bundle),
    };
  }

  Widget _tabContent(DeviceDetailBundle bundle) {
    return switch (_selectedTab) {
      DeviceDetailTab.status => _StatusSummary(bundle: bundle),
      DeviceDetailTab.control => const DeviceSurface(
        child: Text(
          '核心控制已显示在上方，执行结果会在命令状态条中实时反馈。',
          style: TextStyle(
            color: InkPalette.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      DeviceDetailTab.automation => _AutomationSummary(
        deviceType: bundle.device.type,
      ),
      DeviceDetailTab.maintenance => _MaintenanceDetails(bundle: bundle),
    };
  }

  void _showDeviceMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('重命名设备'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('共享设备状态'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.link_off_rounded,
                  color: InkPalette.cinnabar,
                ),
                title: const Text(
                  '解除绑定',
                  style: TextStyle(color: InkPalette.cinnabar),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetrics extends StatelessWidget {
  const _HeroMetrics({required this.bundle});

  final DeviceDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final telemetry = bundle.device.telemetry;
    final primary = telemetry.isEmpty ? null : telemetry.first;
    final secondary = telemetry.length > 1 ? telemetry[1] : null;
    return Row(
      children: [
        Expanded(
          child: DeviceMetric(
            label: primary?.label ?? '设备状态',
            value: primary?.value ?? '正常',
            icon: Icons.monitor_heart_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DeviceMetric(
            label: secondary?.label ?? '电量',
            value: secondary?.value ?? '${bundle.device.batteryLevel}%',
            icon: Icons.battery_charging_full_rounded,
            color: InkPalette.lake,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DeviceMetric(
            label: '告警',
            value: '${bundle.alerts.where((item) => !item.resolved).length}',
            icon: Icons.notifications_active_rounded,
            color: bundle.alerts.isEmpty ? InkPalette.moss : InkPalette.reed,
          ),
        ),
      ],
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.bundle});

  final DeviceDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    return DeviceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DeviceSectionTitle(
            icon: Icons.health_and_safety_rounded,
            title: '设备健康',
          ),
          const SizedBox(height: 10),
          Text(
            bundle.alerts.isEmpty
                ? '设备运行稳定，当前没有未处理告警。'
                : '${bundle.alerts.length} 条设备提醒需要关注。',
            style: const TextStyle(
              color: InkPalette.muted,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final alert in bundle.alerts) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  alert.severity == DomainAlertSeverity.critical
                      ? Icons.error_rounded
                      : Icons.warning_amber_rounded,
                  color: InkPalette.reed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          color: InkPalette.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        alert.message,
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
          ],
        ],
      ),
    );
  }
}

class _AutomationSummary extends StatelessWidget {
  const _AutomationSummary({required this.deviceType});

  final DomainDeviceType deviceType;

  @override
  Widget build(BuildContext context) {
    final items = switch (deviceType) {
      DomainDeviceType.smartTackleBox => ['低电量自动关闭 USB', '高温持续 10 分钟提醒'],
      DomainDeviceType.smartUmbrella => ['超过防风阈值自动收伞', '降雨概率超过 60% 自动收伞'],
      DomainDeviceType.smartPlatform => ['到达钓位提醒校准', '负载异常自动启用安全锁'],
      _ => ['异常状态自动提醒'],
    };
    return DeviceSurface(
      child: Column(
        children: [
          const DeviceSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: '自动化规则',
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            DeviceToggleRow(
              icon: Icons.bolt_rounded,
              title: item,
              subtitle: '已启用',
              value: true,
              onChanged: (_) {},
            ),
            if (item != items.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _MaintenanceSummary extends StatelessWidget {
  const _MaintenanceSummary({
    required this.bundle,
    required this.onFirmwareUpgrade,
    required this.onCalibrate,
  });

  final DeviceDetailBundle bundle;
  final VoidCallback? onFirmwareUpgrade;
  final VoidCallback onCalibrate;

  @override
  Widget build(BuildContext context) {
    return DeviceSurface(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.system_update_alt_rounded),
            title: const Text('固件版本'),
            subtitle: Text(
              bundle.firmware.updateAvailable
                  ? '${bundle.firmware.currentVersion} → ${bundle.firmware.latestVersion}'
                  : bundle.firmware.currentVersion,
            ),
            trailing: bundle.firmware.updateAvailable
                ? FilledButton(
                    onPressed: onFirmwareUpgrade,
                    child: const Text('更新'),
                  )
                : const DeviceStatusPill(
                    icon: Icons.check_rounded,
                    label: '最新',
                    color: InkPalette.moss,
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune_rounded),
            title: const Text('设备校准'),
            subtitle: const Text('传感器与执行器校准记录'),
            trailing: TextButton(
              onPressed: onCalibrate,
              child: const Text('立即校准'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceDetails extends StatelessWidget {
  const _MaintenanceDetails({required this.bundle});

  final DeviceDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    return DeviceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DeviceSectionTitle(
            icon: Icons.build_circle_rounded,
            title: '维护与诊断',
          ),
          const SizedBox(height: 12),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.fact_check_rounded),
            title: Text('执行器自检'),
            trailing: DeviceStatusPill(
              icon: Icons.check_rounded,
              label: '通过',
              color: InkPalette.moss,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.memory_rounded),
            title: const Text('固件通道'),
            subtitle: Text(
              bundle.firmware.mandatory ? '安全更新 · 建议立即安装' : '稳定通道',
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericDevicePanel extends StatelessWidget {
  const _GenericDevicePanel({required this.bundle});

  final DeviceDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    return DeviceSurface(
      child: Column(
        children: [
          DeviceSectionTitle(
            icon: deviceTypeIcon(bundle.device.type),
            title: '设备状态',
          ),
          const SizedBox(height: 12),
          const Text(
            '该设备已接入统一状态、告警和固件能力，专属控制面板将在设备型号注册后自动加载。',
            style: TextStyle(
              color: InkPalette.muted,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmFirmware(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('安装固件更新？'),
          content: const Text('更新期间设备将暂时不可控制，请保持电量充足和网络稳定。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('稍后'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('开始更新'),
            ),
          ],
        ),
      ) ??
      false;
}
