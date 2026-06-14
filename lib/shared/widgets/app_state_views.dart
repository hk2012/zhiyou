import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import 'app_base_components.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIconPill(
                icon: Icons.error_outline_rounded,
                tone: AppTone.danger,
                size: 64,
              ),
              SizedBox(height: AppSpacing.xl.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (message != null) ...[
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: AppSpacing.xxl.h),
                AppActionButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  tone: AppTone.danger,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconPill(icon: icon, tone: AppTone.neutral, size: 58),
              SizedBox(height: AppSpacing.lg.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (message != null) ...[
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
