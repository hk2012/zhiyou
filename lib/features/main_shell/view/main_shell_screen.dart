import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final content = InkPageSwitchTransition(
          triggerKey: navigationShell.currentIndex,
          child: navigationShell,
        );
        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                _DesktopNavigation(
                  currentIndex: navigationShell.currentIndex,
                  onTap: _goBranch,
                  onCenterTap: () =>
                      context.push('${AppRouteNames.creationModal}?entry=nav'),
                  onDevices: () => context.push(AppRouteNames.devices),
                ),
                const VerticalDivider(width: 1, color: InkPalette.line),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          body: content,
          bottomNavigationBar: _InkBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: _goBranch,
            onCenterTap: () =>
                context.push('${AppRouteNames.creationModal}?entry=nav'),
          ),
        );
      },
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
    required this.onDevices,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      color: InkPalette.white.withValues(alpha: 0.96),
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: InkPalette.pine.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phishing_rounded,
              color: InkPalette.pine,
              size: 28,
            ),
          ),
          const SizedBox(height: 24),
          _DesktopNavItem(
            icon: Icons.auto_awesome_rounded,
            label: '首页',
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _DesktopNavItem(
            icon: Icons.place_rounded,
            label: '钓场',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _DesktopNavItem(
            icon: Icons.devices_other_rounded,
            label: '设备',
            active: false,
            onTap: onDevices,
          ),
          _DesktopNavItem(
            icon: Icons.shopping_bag_rounded,
            label: '补给',
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _DesktopNavItem(
            icon: Icons.person_rounded,
            label: '我的',
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          const Spacer(),
          Tooltip(
            message: '开始记录本次作钓',
            child: FilledButton(
              onPressed: onCenterTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(58, 52),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.play_arrow_rounded),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '开钓',
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? InkPalette.pine : InkPalette.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: active
                ? InkPalette.pine.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InkBottomNav extends StatelessWidget {
  const _InkBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(
        10.w,
        0,
        10.w,
        safeBottom > 0 ? safeBottom * 0.72 : 8.h,
      ),
      height: 62.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.rice.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: InkPalette.ink.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: InkPalette.ink.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome_rounded,
                  label: '首页',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.place_outlined,
                  activeIcon: Icons.place_rounded,
                  label: '钓场',
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                InkPressable(
                  onTap: onCenterTap,
                  pressedScale: 0.94,
                  rippleColor: InkPalette.reed,
                  child: SizedBox(
                    width: 48.w,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38.w,
                          height: 38.w,
                          margin: EdgeInsets.only(bottom: 1.h),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [InkPalette.ink, InkPalette.lake],
                            ),
                            border: Border.all(
                              color: InkPalette.rice.withValues(alpha: 0.90),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: InkPalette.pine.withValues(alpha: 0.28),
                                blurRadius: 14,
                                offset: Offset(0, 7.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: InkPalette.white,
                            size: 23.w,
                          ),
                        ),
                        Text(
                          '开钓',
                          maxLines: 1,
                          style: TextStyle(
                            color: InkPalette.ink,
                            fontSize: 10.sp,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: '补给',
                  active: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: '我的',
                  active: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? InkPalette.pine : InkPalette.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 20.w),
            SizedBox(height: 2.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 10.8.sp,
                  height: 1.1,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 14.w : 0,
              height: 2.5.h,
              decoration: BoxDecoration(
                color: InkPalette.pine,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
