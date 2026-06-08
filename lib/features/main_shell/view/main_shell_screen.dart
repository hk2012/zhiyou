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
    return Scaffold(
      extendBody: true,
      body: InkPageSwitchTransition(
        triggerKey: navigationShell.currentIndex,
        child: navigationShell,
      ),
      bottomNavigationBar: _InkBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
        onCenterTap: () => context.push(AppRouteNames.creationModal),
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
        14.w,
        0,
        14.w,
        safeBottom > 0 ? safeBottom : 12.h,
      ),
      height: 72.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InkPalette.rice.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28.r),
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: '首页',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: '钓点',
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                InkPressable(
                  onTap: onCenterTap,
                  pressedScale: 0.94,
                  rippleColor: InkPalette.reed,
                  child: SizedBox(
                    width: 58.w,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52.w,
                          height: 52.w,
                          margin: EdgeInsets.only(bottom: 2.h),
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
                                blurRadius: 18,
                                offset: Offset(0, 9.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: InkPalette.white,
                            size: 30.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.forum_outlined,
                  activeIcon: Icons.forum_rounded,
                  label: '鱼圈',
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
        width: 58.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 23.w),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: active ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 18.w : 0,
              height: 3.h,
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
