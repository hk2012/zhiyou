import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class InkPalette {
  InkPalette._();

  static const ink = Color(0xFF062F32);
  static const pine = Color(0xFF0E3A3A);
  static const lake = Color(0xFF1F5A5A);
  static const moss = Color(0xFF40746E);
  static const reed = Color(0xFFD6B46D);
  static const cinnabar = Color(0xFFCB5A3E);
  static const rice = Color(0xFFF7F1E5);
  static const paper = Color(0xFFF1E7D2);
  static const mist = Color(0xFFE6EEE8);
  static const line = Color(0xFFC7C1B1);
  static const text = Color(0xFF16312F);
  static const muted = Color(0xFF425B56);
  static const faint = Color(0xFF677B76);
  static const white = Color(0xFFFFFFFF);
}

class InkAssets {
  InkAssets._();

  static const ricePaper = 'assets/images/ink_style/rice_paper_bg.png';
  static const homeLakeHero = 'assets/images/ink_style/home_lake_hero.png';
  static const fishingMap = 'assets/images/ink_style/ink_fishing_map.png';
  static const bamboo = 'assets/images/ink_style/bamboo_overlay.png';
  static const badgeFrames = 'assets/images/ink_style/ink_badge_frames.png';
}

const List<String> inkFontFallback = [
  'ZCOOLXiaoWei',
  'Songti SC',
  'STSong',
  'Kaiti SC',
  'STKaiti',
  'Source Han Serif SC',
  'Noto Serif CJK SC',
  'PingFang SC',
  'Hiragino Sans GB',
  'Microsoft YaHei',
  'Noto Sans CJK SC',
  'Arial Unicode MS',
  'sans-serif',
];

const List<String> brushFontFallback = [
  'MaShanZheng',
  'STXingkai',
  'Xingkai SC',
  'HanziPen SC',
  'Hannotate SC',
  'HanziPen TC',
  'Kaiti SC',
  'STKaiti',
  'KaiTi',
  'FZKai-Z03',
  'Songti SC',
  'STSong',
  'PingFang SC',
  'serif',
];

class InkBrand extends StatelessWidget {
  const InkBrand({
    super.key,
    this.compact = false,
    this.color = InkPalette.ink,
    this.subtitleColor = InkPalette.muted,
  });

  final bool compact;
  final Color color;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 28.sp : 42.sp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '江湖钓客',
          style: TextStyle(
            color: color,
            fontSize: titleSize,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            fontFamily: 'MaShanZheng',
            fontFamilyFallback: brushFontFallback,
            shadows: [
              Shadow(
                color: InkPalette.ink.withValues(alpha: 0.18),
                blurRadius: 0,
                offset: Offset(1.w, 1.h),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 5.h : 10.h),
        Container(
          height: compact ? 5.h : 7.h,
          width: compact ? 82.w : 126.w,
          decoration: BoxDecoration(
            color: subtitleColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        SizedBox(height: compact ? 3.h : 7.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '山水之间',
              style: TextStyle(
                color: subtitleColor,
                fontSize: compact ? 10.sp : 12.sp,
                fontWeight: FontWeight.w800,
                fontFamilyFallback: inkFontFallback,
              ),
            ),
            Container(
              width: 18.w,
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              color: subtitleColor.withValues(alpha: 0.45),
            ),
            Text(
              '静钓未来',
              style: TextStyle(
                color: subtitleColor,
                fontSize: compact ? 10.sp : 12.sp,
                fontWeight: FontWeight.w800,
                fontFamilyFallback: inkFontFallback,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InkPage extends StatelessWidget {
  const InkPage({
    super.key,
    required this.child,
    this.bottomInset = 112,
    this.showLandscape = true,
    this.extendBehindStatusBar = false,
  });

  final Widget child;
  final double bottomInset;
  final bool showLandscape;
  final bool extendBehindStatusBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InkPalette.rice,
      extendBody: true,
      body: Stack(
        children: [
          if (showLandscape) const Positioned.fill(child: InkBackdrop()),
          SafeArea(top: !extendBehindStatusBar, bottom: false, child: child),
        ],
      ),
    );
  }
}

class InkBackdrop extends StatelessWidget {
  const InkBackdrop({super.key, this.opacity = 1});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(color: InkPalette.rice)),
          Image.asset(
            InkAssets.ricePaper,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
          CustomPaint(
            painter: _InkBackdropPainter(),
            child: const SizedBox.expand(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.10,
                child: Image.asset(
                  InkAssets.bamboo,
                  fit: BoxFit.cover,
                  alignment: Alignment.topRight,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InkPressable extends StatefulWidget {
  const InkPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.haptic = true,
    this.rippleColor = InkPalette.lake,
    this.enableRipple = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;
  final Color rippleColor;
  final bool enableRipple;

  @override
  State<InkPressable> createState() => _InkPressableState();
}

class _InkPressableState extends State<InkPressable>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _rippleController;
  Offset? _rippleOrigin;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        _setPressed(true);
        if (!widget.enableRipple) return;
        _rippleOrigin = details.localPosition;
        _rippleController
          ..stop()
          ..reset()
          ..forward();
      },
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        if (widget.haptic) HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            widget.child,
            if (widget.enableRipple)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RainRipplePainter(
                          progress: _rippleController.value,
                          origin: _rippleOrigin,
                          color: widget.rippleColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InkLandscapeHero extends StatelessWidget {
  const InkLandscapeHero({
    super.key,
    this.height = 210,
    this.score,
    this.title,
    this.subtitle,
    this.trailing,
    this.bright = true,
  });

  final double height;
  final int? score;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: SizedBox(
        height: height.h,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                InkAssets.homeLakeHero,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(
                    painter: _InkLandscapePainter(bright: bright),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _InkWashOverlayPainter(bright: bright),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      InkPalette.white.withValues(alpha: bright ? 0.14 : 0.04),
                      InkPalette.ink.withValues(alpha: bright ? 0.22 : 0.42),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18.w,
              right: 18.w,
              bottom: 16.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: InkPalette.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              fontFamily: 'MaShanZheng',
                              fontFamilyFallback: brushFontFallback,
                              shadows: const [
                                Shadow(
                                  color: Color(0x66000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        if (subtitle != null) ...[
                          SizedBox(height: 6.h),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: InkPalette.white.withValues(alpha: 0.92),
                              fontSize: 12.sp,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              fontFamilyFallback: inkFontFallback,
                              shadows: const [
                                Shadow(color: Color(0x55000000), blurRadius: 8),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (score != null) ...[
                    SizedBox(width: 12.w),
                    InkScoreRing(score: score!, size: 76),
                  ],
                  if (trailing != null) ...[SizedBox(width: 12.w), trailing!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InkTopBar extends StatelessWidget {
  const InkTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 6.h),
      child: Row(
        children: [
          if (onBack != null) ...[
            InkRoundButton(icon: Icons.arrow_back_rounded, onTap: onBack),
            SizedBox(width: 10.w),
          ] else if (leading != null) ...[
            leading!,
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    fontFamily: 'MaShanZheng',
                    fontFamilyFallback: brushFontFallback,
                  ),
                ),
                Container(
                  height: 5.h,
                  width: 86.w,
                  margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
                  child: CustomPaint(
                    painter: _InkBrushStrokePainter(
                      color: InkPalette.pine.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.muted,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      fontFamilyFallback: inkFontFallback,
                    ),
                  ),
              ],
            ),
          ),
          ...actions.map(
            (child) => Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class InkCard extends StatelessWidget {
  const InkCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(14.r),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFFFFBF2).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: borderColor ?? InkPalette.ink.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: InkPalette.ink.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42.w,
            bottom: -34.h,
            width: 150.w,
            height: 112.h,
            child: Opacity(
              opacity: color == null ? 0.08 : 0,
              child: Image.asset(
                InkAssets.bamboo,
                fit: BoxFit.cover,
                alignment: Alignment.bottomRight,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(painter: _InkCardCornerPainter());
                },
              ),
            ),
          ),
          child,
        ],
      ),
    );

    return InkPressable(onTap: onTap, child: card);
  }
}

class InkGlassCard extends StatelessWidget {
  const InkGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: InkCard(
          padding: padding,
          color: const Color(0xFFFFFBF2).withValues(alpha: 0.90),
          borderColor: InkPalette.ink.withValues(alpha: 0.20),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

class InkSectionHeader extends StatelessWidget {
  const InkSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -5.w,
                      right: -10.w,
                      bottom: 1.h,
                      height: 10.h,
                      child: CustomPaint(
                        painter: _InkBrushStrokePainter(
                          color: InkPalette.pine.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        fontFamily: 'MaShanZheng',
                        fontFamilyFallback: brushFontFallback,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: InkPalette.muted,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      fontFamilyFallback: inkFontFallback,
                    ),
                  ),
              ],
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    action!,
                    style: TextStyle(
                      color: InkPalette.pine,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: InkPalette.pine,
                    size: 16.w,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class InkIconMark extends StatelessWidget {
  const InkIconMark({
    super.key,
    required this.icon,
    this.color = InkPalette.pine,
    this.size = 38,
    this.iconSize,
    this.filled = true,
    this.seal = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final bool filled;
  final bool seal;

  @override
  Widget build(BuildContext context) {
    final side = size.w;
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _InkIconMarkPainter(
                color: color,
                filled: filled,
                seal: seal,
              ),
            ),
          ),
          Icon(
            icon,
            color: seal ? InkPalette.cinnabar : color,
            size: iconSize?.w ?? size.w * 0.50,
          ),
        ],
      ),
    );
  }
}

class InkRoundButton extends StatelessWidget {
  const InkRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.filled = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? badge;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: InkPalette.ink.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4.h),
                      ),
                    ]
                  : null,
            ),
            child: InkIconMark(
              icon: icon,
              color: InkPalette.ink,
              size: 38,
              iconSize: 20,
              filled: filled,
            ),
          ),
          if (badge != null)
            Positioned(
              right: -2.w,
              top: -2.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: InkPalette.cinnabar,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: InkPalette.white, width: 1.5),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: InkPalette.white,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InkChip extends StatelessWidget {
  const InkChip({
    super.key,
    required this.label,
    this.icon,
    this.active = false,
    this.color = InkPalette.pine,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active ? color : InkPalette.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? color : InkPalette.line.withValues(alpha: 0.9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15.w, color: active ? InkPalette.white : color),
              SizedBox(width: 5.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? InkPalette.white : InkPalette.text,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InkMetric extends StatelessWidget {
  const InkMetric({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color = InkPalette.pine,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: InkPalette.paper.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: InkPalette.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            InkIconMark(icon: icon!, color: color, size: 30, iconSize: 16),
            SizedBox(width: 7.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InkPrimaryButton extends StatelessWidget {
  const InkPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = InkPalette.pine,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: busy ? null : onTap,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, InkPalette.lake, 0.42)!],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Center(
          child: busy
              ? const InkTaijiLoader(size: 24, label: '')
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: InkPalette.white, size: 18.w),
                      SizedBox(width: 7.w),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: InkPalette.white,
                        fontSize: 16.sp,
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

class InkTaijiLoader extends StatefulWidget {
  const InkTaijiLoader({super.key, this.size = 42, this.label = 'AI 思考中'});

  final double size;
  final String label;

  @override
  State<InkTaijiLoader> createState() => _InkTaijiLoaderState();
}

class _InkTaijiLoaderState extends State<InkTaijiLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size.w,
              height: widget.size.w,
              child: CustomPaint(
                painter: _InkVortexPainter(progress: _controller.value),
              ),
            ),
            if (widget.label.isNotEmpty) ...[
              SizedBox(width: 8.w),
              Text(
                widget.label,
                style: TextStyle(
                  color: InkPalette.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'MaShanZheng',
                  fontFamilyFallback: brushFontFallback,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class InkPageTransition extends StatelessWidget {
  const InkPageTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final value = curved.value;
        return Stack(
          children: [
            FadeTransition(
              opacity: curved,
              child: Transform.translate(
                offset: Offset((1 - value) * 18.w, 0),
                child: child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _PageInkTransitionPainter(progress: value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class InkPageSwitchTransition extends StatefulWidget {
  const InkPageSwitchTransition({
    super.key,
    required this.triggerKey,
    required this.child,
  });

  final Object triggerKey;
  final Widget child;

  @override
  State<InkPageSwitchTransition> createState() =>
      _InkPageSwitchTransitionState();
}

class _InkPageSwitchTransitionState extends State<InkPageSwitchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void didUpdateWidget(covariant InkPageSwitchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.triggerKey != widget.triggerKey) {
      _controller
        ..stop()
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PageInkTransitionPainter(
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class InkSafetyAlertCard extends StatefulWidget {
  const InkSafetyAlertCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.notifications_active_rounded,
    this.color = InkPalette.reed,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<InkSafetyAlertCard> createState() => _InkSafetyAlertCardState();
}

class _InkSafetyAlertCardState extends State<InkSafetyAlertCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: widget.onTap,
      rippleColor: widget.color,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              constraints: BoxConstraints(minHeight: 92.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: InkPalette.ink,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: widget.color.withValues(alpha: 0.36)),
                boxShadow: [
                  BoxShadow(
                    color: InkPalette.ink.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: Offset(0, 10.h),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NightSafetyPainter(
                        progress: _controller.value,
                        color: widget.color,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 54.w,
                        height: 54.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size.square(54.w),
                              painter: _PulseBellPainter(
                                progress: _controller.value,
                                color: widget.color,
                              ),
                            ),
                            Icon(widget.icon, color: widget.color, size: 25.w),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: InkPalette.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: InkPalette.white.withValues(alpha: 0.78),
                                fontSize: 12.sp,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: InkPalette.white.withValues(alpha: 0.86),
                        size: 22.w,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class InkSearchBox extends StatelessWidget {
  const InkSearchBox({super.key, required this.hint, this.onTap});

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: InkPalette.muted, size: 20.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: InkPalette.faint,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InkScoreRing extends StatelessWidget {
  const InkScoreRing({super.key, required this.score, this.size = 72});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          width: size.h,
          height: size.h,
          child: CustomPaint(
            painter: _ScoreRingPainter(progress),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: InkPalette.white,
                      fontSize: (size * 0.34).h,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '适宜',
                    style: TextStyle(
                      color: InkPalette.white.withValues(alpha: 0.88),
                      fontSize: (size * 0.15).h,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class InkSeal extends StatelessWidget {
  const InkSeal({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
      decoration: BoxDecoration(
        border: Border.all(color: InkPalette.cinnabar, width: 1.2),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: InkPalette.cinnabar,
          fontSize: 12.sp,
          height: 1.15,
          fontWeight: FontWeight.w900,
          fontFamily: 'MaShanZheng',
          fontFamilyFallback: brushFontFallback,
        ),
      ),
    );
  }
}

class InkMiniMap extends StatelessWidget {
  const InkMiniMap({super.key, this.height = 260, this.selectedIndex = 0});

  final double height;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13.r),
      child: SizedBox(
        height: height.h,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                InkAssets.fishingMap,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: InkPalette.rice.withValues(alpha: 0.08),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      InkPalette.rice.withValues(alpha: 0.06),
                      Colors.transparent,
                      InkPalette.ink.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _InkMapPainter(selectedIndex: selectedIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InkInfoRow extends StatelessWidget {
  const InkInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.color = InkPalette.pine,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkIconMark(icon: icon, color: color, size: 38, iconSize: 19),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: InkPalette.text,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: InkPalette.muted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class InkActionTile extends StatelessWidget {
  const InkActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22.w),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class InkSheetAction {
  const InkSheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = InkPalette.pine,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
}

void showInkActionSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  IconData icon = Icons.auto_awesome_rounded,
  Color color = InkPalette.pine,
  List<Widget> children = const [],
  List<InkSheetAction> actions = const [],
  bool showLandscape = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.24),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.86,
            ),
            child: InkGlassCard(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: InkPalette.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    InkInfoRow(
                      icon: icon,
                      title: title,
                      subtitle: subtitle,
                      color: color,
                    ),
                    if (showLandscape) ...[
                      SizedBox(height: 14.h),
                      const InkLandscapeHero(height: 126, bright: true),
                    ],
                    if (children.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      ...children,
                    ],
                    if (actions.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      for (var i = 0; i < actions.length; i++) ...[
                        InkCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 11.h,
                          ),
                          color: InkPalette.paper.withValues(alpha: 0.72),
                          onTap: () {
                            final action = actions[i];
                            Navigator.of(sheetContext).pop();
                            if (action.onTap != null) {
                              action.onTap!.call();
                            } else {
                              _showInkActionFallback(context, action);
                            }
                          },
                          child: InkInfoRow(
                            icon: actions[i].icon,
                            title: actions[i].title,
                            subtitle: actions[i].subtitle,
                            trailing: '进入',
                            color: actions[i].color,
                          ),
                        ),
                        if (i != actions.length - 1) SizedBox(height: 9.h),
                      ],
                    ],
                    SizedBox(height: 16.h),
                    InkPrimaryButton(
                      label: '完成',
                      onTap: () => Navigator.of(sheetContext).pop(),
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _showInkActionFallback(BuildContext context, InkSheetAction action) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: action.color,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '已打开「${action.title}」',
          style: const TextStyle(
            color: InkPalette.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
}

void showInkFeatureSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  IconData icon = Icons.auto_awesome_rounded,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.24),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: InkPalette.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                InkInfoRow(
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  color: InkPalette.pine,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: const [
                    Expanded(
                      child: InkMetric(
                        value: '演示',
                        label: '数据状态',
                        icon: Icons.hub_rounded,
                        color: InkPalette.lake,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: InkMetric(
                        value: '可点',
                        label: '交互状态',
                        icon: Icons.touch_app_rounded,
                        color: InkPalette.moss,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                const InkInfoRow(
                  icon: Icons.verified_rounded,
                  title: '设计原则',
                  subtitle: '先完成路径、反馈和数据结构，再替换真实服务',
                  color: InkPalette.moss,
                ),
                SizedBox(height: 10.h),
                const InkInfoRow(
                  icon: Icons.route_rounded,
                  title: '用户路径',
                  subtitle: '入口、确认、结果和撤销反馈保持完整闭环',
                  color: InkPalette.reed,
                ),
                SizedBox(height: 16.h),
                InkPrimaryButton(
                  label: '知道了',
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _InkBrushStrokePainter extends CustomPainter {
  const _InkBrushStrokePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.16,
        size.width * 0.50,
        size.height * 0.22,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width * 0.96, size.height * 0.85)
      ..cubicTo(
        size.width * 0.65,
        size.height,
        size.width * 0.28,
        size.height * 0.80,
        0,
        size.height * 0.92,
      )
      ..close();
    canvas.drawPath(path, paint);

    final dry = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.height * 0.18)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.34 + i * 0.18);
      canvas.drawLine(
        Offset(size.width * (0.08 + i * 0.05), y),
        Offset(size.width * (0.82 + i * 0.06), y + math.sin(i) * 2),
        dry,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InkBrushStrokePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _InkWashOverlayPainter extends CustomPainter {
  const _InkWashOverlayPainter({required this.bright});

  final bool bright;

  @override
  void paint(Canvas canvas, Size size) {
    final mist = Paint()
      ..color = (bright ? InkPalette.rice : InkPalette.ink).withValues(
        alpha: bright ? 0.10 : 0.14,
      )
      ..style = PaintingStyle.fill;
    final wash = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.62,
        size.width * 0.42,
        size.height * 0.84,
        size.width * 0.62,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.60,
        size.width,
        size.height * 0.82,
        size.width,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wash, mist);

    final birdPaint = Paint()
      ..color = InkPalette.ink.withValues(alpha: bright ? 0.26 : 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.62 + i * 0.08);
      final y = size.height * (0.12 + math.sin(i) * 0.03);
      final bird = Path()
        ..moveTo(x - 5, y)
        ..quadraticBezierTo(x, y - 4, x + 5, y)
        ..quadraticBezierTo(x + 9, y - 3, x + 13, y - 1);
      canvas.drawPath(bird, birdPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkWashOverlayPainter oldDelegate) {
    return oldDelegate.bright != bright;
  }
}

class _RainRipplePainter extends CustomPainter {
  const _RainRipplePainter({
    required this.progress,
    required this.origin,
    required this.color,
  });

  final double progress;
  final Offset? origin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || origin == null) return;
    final center = origin!;
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    for (var i = 0; i < 3; i++) {
      final local = (progress - i * 0.14).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final opacity = (1 - local).clamp(0.0, 1.0);
      final radius = maxRadius * local * 0.42;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.18 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.2 + i * 0.6) * (1 - local * 0.35)
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, paint);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        -math.pi * 0.15,
        math.pi * 0.78,
        false,
        paint..color = InkPalette.white.withValues(alpha: 0.12 * opacity),
      );
    }
    final droplet = Paint()
      ..color = color.withValues(alpha: 0.10 * (1 - progress))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5 + 10 * progress, droplet);
  }

  @override
  bool shouldRepaint(covariant _RainRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.color != color;
  }
}

class _InkVortexPainter extends CustomPainter {
  const _InkVortexPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          InkPalette.white.withValues(alpha: 0.95),
          InkPalette.mist.withValues(alpha: 0.58),
          InkPalette.lake.withValues(alpha: 0.50),
          InkPalette.ink.withValues(alpha: 0.12),
        ],
        stops: const [0.0, 0.30, 0.66, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.96, wash);

    for (var i = 0; i < 9; i++) {
      final start = -math.pi * 0.95 + i * math.pi * 0.22;
      final sweep =
          math.pi * (0.70 + math.sin(progress * math.pi * 2 + i) * 0.10);
      final stroke = Paint()
        ..color = (i.isEven ? InkPalette.ink : InkPalette.white).withValues(
          alpha: i.isEven ? 0.52 : 0.62,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, radius * (0.16 - i * 0.010))
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      final rect = Rect.fromCircle(
        center: center,
        radius: radius * (0.24 + i * 0.086),
      );
      canvas.drawArc(rect, start, sweep, false, stroke);
    }

    final fishPaint = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.62)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final angle = progress * math.pi * 2 + i * math.pi * 0.5;
      final fishCenter = Offset(
        center.dx + math.cos(angle) * radius * 0.70,
        center.dy + math.sin(angle) * radius * 0.48,
      );
      canvas.save();
      canvas.translate(fishCenter.dx, fishCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      final fish = Path()
        ..moveTo(0, -radius * 0.08)
        ..quadraticBezierTo(radius * 0.12, 0, 0, radius * 0.08)
        ..quadraticBezierTo(-radius * 0.12, 0, 0, -radius * 0.08)
        ..close();
      canvas.drawPath(fish, fishPaint);
      canvas.restore();
    }

    canvas.restore();

    if (size.shortestSide >= 72) {
      final aiPainter = TextPainter(
        text: TextSpan(
          text: 'AI',
          style: TextStyle(
            color: InkPalette.white.withValues(alpha: 0.94),
            fontSize: radius * 0.62,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      aiPainter.paint(
        canvas,
        Offset(center.dx - aiPainter.width / 2, center.dy - radius * 0.30),
      );

      final thinkingPainter = TextPainter(
        text: TextSpan(
          text: '思考中',
          style: TextStyle(
            color: InkPalette.white.withValues(alpha: 0.78),
            fontSize: radius * 0.17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      thinkingPainter.paint(
        canvas,
        Offset(
          center.dx - thinkingPainter.width / 2,
          center.dy + radius * 0.22,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InkVortexPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PageInkTransitionPainter extends CustomPainter {
  const _PageInkTransitionPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final visibility = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final x = size.width * Curves.easeInOutCubic.transform(progress);
    final center = Offset(x, size.height * 0.48);
    final radius = size.shortestSide * (0.22 + visibility * 0.14);

    final wash = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.14 * visibility)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius, wash);

    final dry = Paint()
      ..color = InkPalette.pine.withValues(alpha: 0.34 * visibility)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * visibility + 1
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    final stroke = Path()
      ..moveTo(x - size.width * 0.34, size.height * 0.38)
      ..cubicTo(
        x - size.width * 0.16,
        size.height * 0.26,
        x + size.width * 0.06,
        size.height * 0.58,
        x + size.width * 0.30,
        size.height * 0.42,
      );
    canvas.drawPath(stroke, dry);

    final arrow = Paint()
      ..color = InkPalette.lake.withValues(alpha: 0.42 * visibility)
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(x + radius * 0.42, center.dy)
      ..lineTo(x + radius * 0.06, center.dy - radius * 0.17)
      ..lineTo(x + radius * 0.12, center.dy + radius * 0.17)
      ..close();
    canvas.drawPath(arrowPath, arrow);
  }

  @override
  bool shouldRepaint(covariant _PageInkTransitionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NightSafetyPainter extends CustomPainter {
  const _NightSafetyPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF071B2A),
          InkPalette.ink,
          const Color(0xFF102E3C),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final moonPaint = Paint()
      ..color = color.withValues(
        alpha: 0.16 + 0.05 * math.sin(progress * math.pi * 2),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.18),
      size.width * 0.10,
      moonPaint,
    );

    final mountain = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.52)
      ..style = PaintingStyle.fill;
    final ridge = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.20, size.height * 0.60)
      ..lineTo(size.width * 0.42, size.height * 0.78)
      ..lineTo(size.width * 0.62, size.height * 0.54)
      ..lineTo(size.width * 0.86, size.height * 0.77)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ridge, mountain);

    final water = Paint()
      ..color = InkPalette.lake.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.72 + i * 0.045);
      final offset = math.sin(progress * math.pi * 2 + i) * 6;
      canvas.drawLine(
        Offset(size.width * 0.10 + offset, y),
        Offset(size.width * 0.88 + offset, y + math.sin(i) * 2),
        water,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NightSafetyPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _PulseBellPainter extends CustomPainter {
  const _PulseBellPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.shortestSide * 0.34;
    for (var i = 0; i < 2; i++) {
      final local = ((progress + i * 0.35) % 1.0);
      final alpha = (1 - local) * 0.24;
      canvas.drawCircle(
        center,
        baseRadius + local * size.shortestSide * 0.18,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = InkPalette.ink.withValues(alpha: 0.58)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = color.withValues(alpha: 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _PulseBellPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _InkIconMarkPainter extends CustomPainter {
  const _InkIconMarkPainter({
    required this.color,
    required this.filled,
    required this.seal,
  });

  final Color color;
  final bool filled;
  final bool seal;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;

    if (filled) {
      canvas.drawCircle(
        center,
        radius * 0.86,
        Paint()..color = InkPalette.white.withValues(alpha: 0.76),
      );
    }

    if (seal) {
      final sealRect = RRect.fromRectAndRadius(
        rect.deflate(size.shortestSide * 0.13),
        Radius.circular(size.shortestSide * 0.10),
      );
      canvas.drawRRect(
        sealRect,
        Paint()
          ..color = InkPalette.cinnabar.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        sealRect,
        Paint()
          ..color = InkPalette.cinnabar.withValues(alpha: 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      return;
    }

    final ring = Paint()
      ..color = color.withValues(alpha: 0.44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final oval = rect.deflate(size.shortestSide * 0.10);
    canvas.drawArc(oval, -math.pi * 0.18, math.pi * 1.52, false, ring);
    canvas.drawArc(
      oval.shift(Offset(size.width * 0.02, -size.height * 0.01)),
      math.pi * 1.46,
      math.pi * 0.44,
      false,
      ring..color = color.withValues(alpha: 0.24),
    );

    final leafPaint = Paint()
      ..color = InkPalette.pine.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    final stem = Paint()
      ..color = InkPalette.pine.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    final base = Offset(size.width * 0.70, size.height * 0.76);
    canvas.drawLine(
      base,
      base.translate(size.width * 0.16, -size.height * 0.18),
      stem,
    );
    for (var i = 0; i < 3; i++) {
      final leaf = Path()
        ..moveTo(
          base.dx + i * size.width * 0.04,
          base.dy - i * size.height * 0.04,
        )
        ..quadraticBezierTo(
          base.dx + size.width * (0.12 + i * 0.03),
          base.dy - size.height * (0.09 + i * 0.02),
          base.dx + size.width * (0.18 + i * 0.02),
          base.dy - size.height * (0.04 + i * 0.05),
        )
        ..quadraticBezierTo(
          base.dx + size.width * (0.10 + i * 0.02),
          base.dy - size.height * (0.02 + i * 0.04),
          base.dx + i * size.width * 0.04,
          base.dy - i * size.height * 0.04,
        );
      canvas.drawPath(leaf, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkIconMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.filled != filled ||
        oldDelegate.seal != seal;
  }
}

class _InkCardCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mountain = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    final far = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.34,
        size.width * 0.36,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.28,
        size.width * 0.74,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.48,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(far, mountain);

    final water = Paint()
      ..color = InkPalette.lake.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.72 + i * 0.055);
      canvas.drawLine(
        Offset(size.width * 0.18, y),
        Offset(size.width * 0.96, y + math.sin(i) * 2),
        water,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InkBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFCF4), Color(0xFFF2F6EE)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final grainPaint = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.012)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 90; i++) {
      final x = (i * 47) % size.width;
      final y = (i * 83) % size.height;
      canvas.drawCircle(Offset(x, y), (i % 3 + 1) * 0.45, grainPaint);
    }

    final wash = Paint()
      ..color = InkPalette.lake.withValues(alpha: 0.038)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.02,
        size.width * 0.5,
        size.height * 0.1,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.18,
        size.width,
        size.height * 0.08,
      )
      ..lineTo(size.width, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.26,
        0,
        size.height * 0.36,
      )
      ..close();
    canvas.drawPath(path, wash);

    final farMountain = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.036)
      ..style = PaintingStyle.fill;
    for (var layer = 0; layer < 3; layer++) {
      final base = size.height * (0.20 + layer * 0.065);
      final mountain = Path()..moveTo(-20, base + 45);
      for (var x = -20.0; x <= size.width + 40; x += size.width / 4) {
        mountain.quadraticBezierTo(
          x + size.width / 9,
          base - 24 - math.sin(x / 70 + layer) * 12,
          x + size.width / 4,
          base + 38,
        );
      }
      mountain.lineTo(size.width + 40, base + 88);
      mountain.lineTo(-20, base + 88);
      mountain.close();
      canvas.drawPath(mountain, farMountain);
    }

    final bottomMountain = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.052)
      ..style = PaintingStyle.fill;
    final bottom = Path()
      ..moveTo(0, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.86,
        size.width * 0.34,
        size.height * 0.95,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.82,
        size.width,
        size.height * 0.94,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bottom, bottomMountain);

    final line = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.032)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.16 + i * 0.09);
      final wave = Path()..moveTo(-20, y);
      for (var x = -20.0; x < size.width + 20; x += 42) {
        wave.quadraticBezierTo(x + 21, y + (i.isEven ? 5 : -5), x + 42, y);
      }
      canvas.drawPath(wave, line);
    }

    final bambooPaint = Paint()
      ..color = InkPalette.pine.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final bambooX = size.width - 34;
    canvas.drawLine(
      Offset(bambooX, size.height * 0.02),
      Offset(bambooX - 18, size.height * 0.42),
      bambooPaint,
    );
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.06 + i * 0.055);
      final leftLeaf = Path()
        ..moveTo(bambooX - i * 2, y)
        ..quadraticBezierTo(bambooX - 40, y - 9, bambooX - 58, y + 4);
      final rightLeaf = Path()
        ..moveTo(bambooX - i * 2, y + 7)
        ..quadraticBezierTo(bambooX + 22, y - 2, bambooX + 34, y + 10);
      canvas.drawPath(leftLeaf, bambooPaint);
      canvas.drawPath(rightLeaf, bambooPaint);
    }

    final boatPaint = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final boatY = size.height * 0.80;
    final boat = Path()
      ..moveTo(size.width * 0.10, boatY)
      ..quadraticBezierTo(
        size.width * 0.18,
        boatY + 18,
        size.width * 0.30,
        boatY,
      )
      ..quadraticBezierTo(
        size.width * 0.22,
        boatY + 28,
        size.width * 0.12,
        boatY + 16,
      )
      ..close();
    canvas.drawPath(boat, boatPaint);
    canvas.drawLine(
      Offset(size.width * 0.20, boatY - 4),
      Offset(size.width * 0.34, boatY - 48),
      Paint()
        ..color = InkPalette.ink.withValues(alpha: 0.12)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    final fishPaint = Paint()
      ..color = InkPalette.lake.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 5; i++) {
      final center = Offset(size.width * (0.16 + i * 0.16), size.height * 0.86);
      final fish = Path()
        ..moveTo(center.dx - 13, center.dy)
        ..quadraticBezierTo(center.dx, center.dy - 8, center.dx + 16, center.dy)
        ..quadraticBezierTo(center.dx, center.dy + 8, center.dx - 13, center.dy)
        ..moveTo(center.dx + 16, center.dy)
        ..lineTo(center.dx + 25, center.dy - 7)
        ..moveTo(center.dx + 16, center.dy)
        ..lineTo(center.dx + 25, center.dy + 7);
      canvas.drawPath(fish, fishPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InkLandscapePainter extends CustomPainter {
  const _InkLandscapePainter({required this.bright});

  final bool bright;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bright
            ? const [Color(0xFFDDEDE9), Color(0xFF8BB2B7), Color(0xFFF1D98E)]
            : const [Color(0xFF34565C), Color(0xFF8FAEAC), Color(0xFFF4D486)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final sunPaint = Paint()..color = const Color(0xFFFFD26F);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.43),
      18.r,
      sunPaint,
    );

    void drawMountain(Color color, double baseY, double amp, double shift) {
      final path = Path()..moveTo(0, baseY);
      for (var x = 0.0; x <= size.width; x += size.width / 5) {
        path.lineTo(
          x + shift,
          baseY - amp * (0.45 + math.sin(x / 55 + shift) * 0.35),
        );
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    drawMountain(
      InkPalette.ink.withValues(alpha: 0.18),
      size.height * 0.66,
      70,
      -20,
    );
    drawMountain(
      InkPalette.lake.withValues(alpha: 0.24),
      size.height * 0.72,
      48,
      14,
    );
    drawMountain(
      InkPalette.ink.withValues(alpha: 0.32),
      size.height * 0.82,
      38,
      36,
    );

    final water = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              InkPalette.lake.withValues(alpha: 0.34),
              InkPalette.ink.withValues(alpha: 0.48),
            ],
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * 0.62,
              size.width,
              size.height * 0.38,
            ),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      water,
    );

    final ripplePaint = Paint()
      ..color = InkPalette.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.66 + i * 0.04);
      canvas.drawLine(
        Offset(size.width * 0.14, y),
        Offset(size.width * (0.86 - i * 0.03), y + math.sin(i) * 2),
        ripplePaint,
      );
    }

    final boatPaint = Paint()..color = InkPalette.ink.withValues(alpha: 0.75);
    final boat = Path()
      ..moveTo(size.width * 0.14, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.75,
        size.width * 0.34,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.78,
        size.width * 0.16,
        size.height * 0.74,
      )
      ..close();
    canvas.drawPath(boat, boatPaint);
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.64),
      5.r,
      boatPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.65),
      Offset(size.width * 0.4, size.height * 0.52),
      Paint()
        ..color = InkPalette.ink.withValues(alpha: 0.68)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _InkLandscapePainter oldDelegate) {
    return oldDelegate.bright != bright;
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final base = Paint()
      ..color = InkPalette.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFF7AD8B3), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _InkMapPainter extends CustomPainter {
  const _InkMapPainter({required this.selectedIndex});

  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds.deflate(0.7),
      Paint()
        ..color = InkPalette.ink.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final markers = [
      Offset(size.width * 0.20, size.height * 0.35),
      Offset(size.width * 0.54, size.height * 0.47),
      Offset(size.width * 0.78, size.height * 0.31),
      Offset(size.width * 0.38, size.height * 0.72),
    ];
    final labels = ['花港', '浅湾', '回水', '泊点'];
    for (var i = 0; i < markers.length; i++) {
      final selected = i == selectedIndex;
      final p = markers[i];
      final ringColor = selected ? InkPalette.cinnabar : InkPalette.ink;
      if (selected) {
        canvas.drawCircle(
          p,
          31.r,
          Paint()..color = InkPalette.reed.withValues(alpha: 0.11),
        );
      }
      for (var ring = 0; ring < 3; ring++) {
        canvas.drawCircle(
          p.translate(math.sin(ring) * 1.2, math.cos(ring) * 1.0),
          (selected ? 15 : 12).r + ring * 1.5,
          Paint()
            ..color = ringColor.withValues(alpha: selected ? 0.56 : 0.32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = selected ? 1.6 : 1.1,
        );
      }
      canvas.drawCircle(
        p,
        selected ? 6.r : 4.5.r,
        Paint()
          ..color = (selected ? InkPalette.cinnabar : InkPalette.pine)
              .withValues(alpha: 0.90),
      );
      final label = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: selected ? InkPalette.cinnabar : InkPalette.ink,
            fontSize: selected ? 13.sp : 12.sp,
            fontWeight: FontWeight.w900,
            fontFamily: selected ? 'MaShanZheng' : 'ZCOOLXiaoWei',
            fontFamilyFallback: selected ? brushFontFallback : inkFontFallback,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = (p.dx - label.width / 2)
          .clamp(8.0, size.width - label.width - 8)
          .toDouble();
      final labelY = p.dy + (selected ? 18.r : 16.r);
      final labelRect = Rect.fromLTWH(
        labelX - 6,
        labelY - 3,
        label.width + 12,
        label.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, Radius.circular(7.r)),
        Paint()..color = InkPalette.rice.withValues(alpha: 0.76),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, Radius.circular(7.r)),
        Paint()
          ..color = (selected ? InkPalette.cinnabar : InkPalette.ink)
              .withValues(alpha: selected ? 0.26 : 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      label.paint(canvas, Offset(labelX, labelY));
    }

    final title = TextPainter(
      text: TextSpan(
        text: '水墨鱼情图',
        style: TextStyle(
          color: InkPalette.ink.withValues(alpha: 0.80),
          fontSize: 17.sp,
          fontWeight: FontWeight.w900,
          fontFamily: 'MaShanZheng',
          fontFamilyFallback: brushFontFallback,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, Offset(14, 13));
    canvas.drawLine(
      Offset(15, 35),
      Offset(82, 35),
      Paint()
        ..color = InkPalette.ink.withValues(alpha: 0.26)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    final sealRect = Rect.fromLTWH(size.width - 58, size.height - 42, 38, 28);
    canvas.drawRect(
      sealRect,
      Paint()
        ..color = InkPalette.cinnabar.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final seal = TextPainter(
      text: TextSpan(
        text: '鱼图',
        style: TextStyle(
          color: InkPalette.cinnabar.withValues(alpha: 0.86),
          fontSize: 13.sp,
          fontWeight: FontWeight.w900,
          fontFamily: 'MaShanZheng',
          fontFamilyFallback: brushFontFallback,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    seal.paint(
      canvas,
      Offset(
        sealRect.center.dx - seal.width / 2,
        sealRect.center.dy - seal.height / 2,
      ),
    );

    final scalePaint = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.42)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final scaleY = size.height - 23;
    canvas.drawLine(Offset(18, scaleY), Offset(72, scaleY), scalePaint);
    canvas.drawLine(Offset(18, scaleY - 4), Offset(18, scaleY + 4), scalePaint);
    canvas.drawLine(Offset(72, scaleY - 4), Offset(72, scaleY + 4), scalePaint);
  }

  @override
  bool shouldRepaint(covariant _InkMapPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}
