import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({
    super.key,
    required this.title,
    this.leftPadding,
    this.bottomPadding,
  });

  final String title;
  final double? leftPadding;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding ?? 20.w,
        bottom: bottomPadding ?? 8.h,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class AppListGroup extends StatelessWidget {
  const AppListGroup({
    super.key,
    required this.children,
    this.horizontalPadding,
    this.borderRadius,
    this.dividerIndent,
  });

  final List<Widget> children;
  final double? horizontalPadding;
  final double? borderRadius;
  final double? dividerIndent;

  @override
  Widget build(BuildContext context) {
    final group = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        ),
        boxShadow: [AppShadows.ambientShadow],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 0,
                  indent: dividerIndent ?? 60.w,
                  color: AppColors.surfaceContainerLow,
                ),
            ],
          );
        }).toList(),
      ),
    );

    final padding = horizontalPadding;
    if (padding == null || padding == 0) return group;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: group,
    );
  }
}

class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size,
  });

  final IconData icon;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final boxSize = size ?? 36.w;
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: color, size: 19.w),
    );
  }
}

class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.onTap,
    this.verticalPadding,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;
  final double? verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: verticalPadding ?? 12.h,
          ),
          child: Row(
            children: [
              AppIconBox(icon: icon),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(width: 6.w),
              Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
                size: 20.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
