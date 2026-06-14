import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius,
    this.color,
    this.borderColor,
    this.shadow = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final Color? color;
  final Color? borderColor;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular((radius ?? AppRadii.lg).r),
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: shadow ? [AppShadows.cardShadow] : null,
    );

    final content = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(AppSpacing.xl.r),
      clipBehavior: Clip.antiAlias,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular((radius ?? AppRadii.lg).r),
        child: content,
      ),
    );
  }
}

class AppIconPill extends StatelessWidget {
  const AppIconPill({
    super.key,
    required this.icon,
    this.tone = AppTone.brand,
    this.size = 40,
    this.iconSize,
    this.solid = false,
  });

  final IconData icon;
  final AppTone tone;
  final double size;
  final double? iconSize;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.colors;
    final side = size.w;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: solid ? toneColors.foreground : toneColors.background,
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        border: Border.all(
          color: solid ? Colors.transparent : toneColors.border,
        ),
      ),
      child: Icon(
        icon,
        color: solid ? AppColors.onInverse : toneColors.foreground,
        size: (iconSize ?? size * 0.48).w,
      ),
    );
  }
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppTone.neutral,
    this.solid = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final AppTone tone;
  final bool solid;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.colors;
    final foreground = solid ? AppColors.onInverse : toneColors.foreground;
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 24.h : 28.h),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md.w : AppSpacing.lg.w,
        vertical: compact ? AppSpacing.xs.h : AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: solid ? toneColors.foreground : toneColors.background,
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
        border: Border.all(
          color: solid ? Colors.transparent : toneColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foreground, size: compact ? 12.w : 14.w),
            SizedBox(width: AppSpacing.xs.w),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: compact ? 11.sp : 12.sp,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = AppTone.brand,
    this.variant = AppButtonVariant.primary,
    this.busy = false,
    this.height = 46,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppTone tone;
  final AppButtonVariant variant;
  final bool busy;
  final double height;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.colors;
    final disabled = onPressed == null || busy;
    final isPrimary = variant == AppButtonVariant.primary;
    final foreground = isPrimary ? AppColors.onInverse : toneColors.foreground;
    final background = switch (variant) {
      AppButtonVariant.primary => toneColors.foreground,
      AppButtonVariant.secondary => toneColors.background,
      AppButtonVariant.ghost => Colors.transparent,
    };
    final borderColor = switch (variant) {
      AppButtonVariant.primary => Colors.transparent,
      AppButtonVariant.secondary => toneColors.border,
      AppButtonVariant.ghost => Colors.transparent,
    };

    final child = AnimatedOpacity(
      duration: AppDurations.fast,
      opacity: disabled ? 0.58 : 1,
      child: Container(
        height: height.h,
        width: expanded ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
        decoration: BoxDecoration(
          color: disabled ? AppColors.surfacePressed : background,
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
          border: Border.all(color: disabled ? AppColors.border : borderColor),
          boxShadow: isPrimary && !disabled
              ? [
                  BoxShadow(
                    color: toneColors.foreground.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: Offset(0, 8.h),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: foreground, size: 17.w),
                        SizedBox(width: AppSpacing.sm.w),
                      ],
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: disabled ? AppColors.textDisabled : foreground,
                          fontSize: 14.sp,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
        child: child,
      ),
    );
  }
}

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone = AppTone.brand,
    this.trailing,
  });

  final String value;
  final String label;
  final IconData? icon;
  final AppTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: EdgeInsets.all(AppSpacing.lg.r),
      shadow: false,
      color: AppColors.surfaceBase,
      child: Row(
        children: [
          if (icon != null) ...[
            AppIconPill(icon: icon!, tone: tone, size: 36),
            SizedBox(width: AppSpacing.lg.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20.sp,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  label,
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
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: AppSpacing.lg.w),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page.w,
        AppSpacing.section.h,
        AppSpacing.page.w,
        AppSpacing.md.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                    fontSize: 18.sp,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
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
                      fontSize: 12.5.sp,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(width: AppSpacing.lg.w),
            AppActionButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.ghost,
              height: 34,
            ),
          ],
        ],
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.tone = AppTone.brand,
    this.height = 7,
  });

  final double value;
  final AppTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final toneColors = tone.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: Stack(
        children: [
          Container(height: height.h, color: toneColors.background),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: height.h,
              decoration: BoxDecoration(
                color: toneColors.foreground,
                borderRadius: BorderRadius.circular(AppRadii.pill.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({
    super.key,
    required this.icon,
    this.tone = AppTone.device,
    this.label,
    this.aspectRatio = 1.6,
  });

  final IconData icon;
  final AppTone tone;
  final String? label;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.colors;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [toneColors.background, AppColors.surfaceBase],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg.r),
          border: Border.all(color: toneColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIconPill(icon: icon, tone: tone, solid: true),
            if (label != null) ...[
              SizedBox(height: AppSpacing.md.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: toneColors.foreground,
                    fontSize: 12.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
