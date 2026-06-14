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
        left: leftPadding ?? AppSpacing.page.w,
        bottom: bottomPadding ?? AppSpacing.md.h,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.textTertiary,
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
    final radius = borderRadius ?? AppRadii.lg.r;
    final group = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: dividerIndent ?? 62.w,
                  color: AppColors.divider,
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
    this.color = AppColors.brand,
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        border: Border.all(color: color.withValues(alpha: 0.16)),
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
            horizontal: AppSpacing.xl.w,
            vertical: verticalPadding ?? AppSpacing.lg.h,
          ),
          child: Row(
            children: [
              AppIconBox(icon: icon),
              SizedBox(width: AppSpacing.lg.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: AppSpacing.xs.h),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5.sp,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null) ...[
                SizedBox(width: AppSpacing.lg.w),
                Text(
                  trailingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
              SizedBox(width: AppSpacing.xs.w),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
