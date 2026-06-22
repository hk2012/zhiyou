import 'package:flutter/material.dart';

import '../../../../core/domain/app_domain_models.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../shared/widgets/ink_app_widgets.dart';
import '../../../home/data/device_models.dart';
import '../../application/device_center_controller.dart';

typedef DeviceCommandHandler =
    Future<void> Function(
      String command,
      Map<String, dynamic> parameters, {
      bool confirmed,
    });

IconData deviceTypeIcon(DomainDeviceType type) => switch (type) {
  DomainDeviceType.smartTackleBox => Icons.kitchen_rounded,
  DomainDeviceType.smartUmbrella => Icons.umbrella_rounded,
  DomainDeviceType.smartPlatform => Icons.deck_rounded,
  DomainDeviceType.smartFloat => Icons.sensors_rounded,
  DomainDeviceType.fishFinder => Icons.radar_rounded,
  DomainDeviceType.nightLight => Icons.lightbulb_rounded,
  _ => Icons.hub_rounded,
};

Color deviceTypeColor(DomainDeviceType type) => switch (type) {
  DomainDeviceType.smartTackleBox => InkPalette.pine,
  DomainDeviceType.smartUmbrella => InkPalette.moss,
  DomainDeviceType.smartPlatform => InkPalette.reed,
  DomainDeviceType.smartFloat => InkPalette.lake,
  _ => InkPalette.pine,
};

class DeviceHeader extends StatelessWidget {
  const DeviceHeader({super.key, required this.device, required this.source});

  final Device device;
  final String source;

  @override
  Widget build(BuildContext context) {
    final color = deviceTypeColor(device.type);
    return DeviceSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Icon(deviceTypeIcon(device.type), color: color, size: 31),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: InkPalette.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DeviceStatusPill(
                      icon: device.isOnline
                          ? Icons.circle
                          : Icons.pause_circle_rounded,
                      label: device.isOnline
                          ? context.l10n.deviceOnline
                          : context.l10n.deviceStandby,
                      color: device.isOnline
                          ? InkPalette.pine
                          : InkPalette.faint,
                    ),
                    DeviceStatusPill(
                      icon: Icons.battery_5_bar_rounded,
                      label: '${device.batteryLevel}%',
                      color: device.isLowBattery
                          ? InkPalette.reed
                          : InkPalette.lake,
                    ),
                    DeviceStatusPill(
                      icon: Icons.network_cell_rounded,
                      label: device.signalLevel >= 70
                          ? context.l10n.deviceStrongSignal
                          : context.l10n.deviceWeakSignal,
                      color: device.signalLevel >= 70
                          ? InkPalette.pine
                          : InkPalette.reed,
                    ),
                    DeviceStatusPill(
                      icon: source == 'api'
                          ? Icons.cloud_done_rounded
                          : Icons.science_rounded,
                      label: source == 'api'
                          ? context.l10n.deviceRealtimeApi
                          : context.l10n.deviceLocalDemo,
                      color: source == 'api'
                          ? InkPalette.lake
                          : InkPalette.reed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceStatusPill extends StatelessWidget {
  const DeviceStatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceTabBar extends StatelessWidget {
  const DeviceTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DeviceDetailTab selected;
  final ValueChanged<DeviceDetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      DeviceDetailTab.status: l10n.deviceTabStatus,
      DeviceDetailTab.control: l10n.deviceTabControl,
      DeviceDetailTab.automation: l10n.deviceTabAutomation,
      DeviceDetailTab.maintenance: l10n.deviceTabMaintenance,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: InkPalette.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InkPalette.line),
      ),
      child: Row(
        children: [
          for (final tab in DeviceDetailTab.values)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(tab),
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == tab
                        ? InkPalette.pine
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[tab]!,
                    style: TextStyle(
                      color: selected == tab
                          ? InkPalette.white
                          : InkPalette.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DeviceSurface extends StatelessWidget {
  const DeviceSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? InkPalette.line),
        boxShadow: [
          BoxShadow(
            color: InkPalette.ink.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DeviceSectionTitle extends StatelessWidget {
  const DeviceSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: InkPalette.pine),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: InkPalette.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class DeviceMetric extends StatelessWidget {
  const DeviceMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = InkPalette.pine,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: InkPalette.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: InkPalette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCommandBanner extends StatelessWidget {
  const DeviceCommandBanner({super.key, required this.state, this.onDetails});

  final DeviceControlState state;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final receipt = state.latestReceipt;
    if (receipt == null && state.errorMessage.isEmpty && !state.isSubmitting) {
      return const SizedBox.shrink();
    }
    final color = state.errorMessage.isNotEmpty
        ? InkPalette.cinnabar
        : state.needsConfirmation
        ? InkPalette.reed
        : receipt?.succeeded == true
        ? InkPalette.pine
        : InkPalette.lake;
    final label = state.isSubmitting
        ? '命令下发中'
        : state.errorMessage.isNotEmpty
        ? state.errorMessage
        : state.needsConfirmation
        ? '等待安全确认'
        : '执行成功 · ${receipt?.commandId ?? ''}';
    return DeviceSurface(
      borderColor: color.withValues(alpha: 0.28),
      child: Row(
        children: [
          if (state.isSubmitting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(
              state.needsConfirmation
                  ? Icons.verified_user_rounded
                  : receipt?.succeeded == true
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: color,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          if (receipt != null)
            IconButton(
              tooltip: '查看命令详情',
              onPressed: onDetails,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    );
  }
}

class DeviceToggleRow extends StatelessWidget {
  const DeviceToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.color = InkPalette.pine,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: InkPalette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: InkPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeTrackColor: color),
      ],
    );
  }
}
