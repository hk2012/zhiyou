import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

class AppScenicBackdrop extends StatelessWidget {
  const AppScenicBackdrop({
    super.key,
    this.icon = Icons.waves,
    this.accent = AppColors.primaryContainer,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6EACF6), Color(0xFF0E61A6), Color(0xFF121920)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -42.h,
            right: -36.w,
            child: _softCircle(140.w, accent.withValues(alpha: 0.22)),
          ),
          Positioned(
            left: -52.w,
            bottom: 18.h,
            child: _softCircle(170.w, Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28.h,
            child: Icon(
              icon,
              size: 96.w,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            left: -24.w,
            right: -24.w,
            bottom: -18.h,
            child: Column(
              children: [
                _wave(0.14),
                SizedBox(height: 10.h),
                _wave(0.09),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppVisualPlaceholder extends StatelessWidget {
  const AppVisualPlaceholder({
    super.key,
    required this.icon,
    required this.label,
    this.accent = AppColors.primary,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            const Color(0xFFEAF2F8),
            const Color(0xFFD9E8F2),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -28.h,
            right: -24.w,
            child: _softCircle(86.w, Colors.white.withValues(alpha: 0.44)),
          ),
          Positioned(
            bottom: -34.h,
            left: -22.w,
            child: _softCircle(112.w, accent.withValues(alpha: 0.12)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32.w, color: accent.withValues(alpha: 0.78)),
                if (showLabel) ...[
                  SizedBox(height: 6.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.64),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppAvatarPlaceholder extends StatelessWidget {
  const AppAvatarPlaceholder({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final avatarSize = size ?? 100.w;
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6EACF6), Color(0xFF0E61A6)],
        ),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: Icon(Icons.person, size: avatarSize * 0.48, color: Colors.white),
    );
  }
}

Widget _softCircle(double size, Color color) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

Widget _wave(double opacity) {
  return Container(
    height: 28.h,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(999),
    ),
  );
}
