import 'package:flutter/material.dart';

enum AppTone {
  neutral,
  brand,
  info,
  success,
  warning,
  danger,
  commerce,
  device,
}

class AppToneColors {
  const AppToneColors({
    required this.foreground,
    required this.background,
    required this.border,
    required this.strong,
  });

  final Color foreground;
  final Color background;
  final Color border;
  final Color strong;
}

extension AppToneColorsX on AppTone {
  AppToneColors get colors {
    switch (this) {
      case AppTone.brand:
        return const AppToneColors(
          foreground: AppColors.brand,
          background: AppColors.brandSoft,
          border: AppColors.brandBorder,
          strong: AppColors.brand,
        );
      case AppTone.info:
        return const AppToneColors(
          foreground: AppColors.info,
          background: AppColors.infoSoft,
          border: AppColors.infoBorder,
          strong: AppColors.info,
        );
      case AppTone.success:
        return const AppToneColors(
          foreground: AppColors.success,
          background: AppColors.successSoft,
          border: AppColors.successBorder,
          strong: AppColors.success,
        );
      case AppTone.warning:
        return const AppToneColors(
          foreground: AppColors.warning,
          background: AppColors.warningSoft,
          border: AppColors.warningBorder,
          strong: AppColors.warning,
        );
      case AppTone.danger:
        return const AppToneColors(
          foreground: AppColors.danger,
          background: AppColors.dangerSoft,
          border: AppColors.dangerBorder,
          strong: AppColors.danger,
        );
      case AppTone.commerce:
        return const AppToneColors(
          foreground: AppColors.commerce,
          background: AppColors.commerceSoft,
          border: AppColors.commerceBorder,
          strong: AppColors.commerce,
        );
      case AppTone.device:
        return const AppToneColors(
          foreground: AppColors.device,
          background: AppColors.deviceSoft,
          border: AppColors.deviceBorder,
          strong: AppColors.device,
        );
      case AppTone.neutral:
        return const AppToneColors(
          foreground: AppColors.textSecondary,
          background: AppColors.surfaceMuted,
          border: AppColors.border,
          strong: AppColors.textPrimary,
        );
    }
  }
}

class AppColors {
  AppColors._();

  static const Color brand = Color(0xFF0E6F68);
  static const Color brandPressed = Color(0xFF0A5752);
  static const Color brandSoft = Color(0xFFE4F4F0);
  static const Color brandBorder = Color(0xFF9BCFC8);

  static const Color info = Color(0xFF1F7AA8);
  static const Color infoPressed = Color(0xFF176587);
  static const Color infoSoft = Color(0xFFE7F4F8);
  static const Color infoBorder = Color(0xFFA9D7E6);

  static const Color commerce = Color(0xFFD9902F);
  static const Color commercePressed = Color(0xFFB8731E);
  static const Color commerceSoft = Color(0xFFFFF3D9);
  static const Color commerceBorder = Color(0xFFEBC986);

  static const Color success = Color(0xFF3F8F5A);
  static const Color successPressed = Color(0xFF2F7448);
  static const Color successSoft = Color(0xFFEAF5EC);
  static const Color successBorder = Color(0xFFB8DDBF);

  static const Color warning = Color(0xFFF97316);
  static const Color warningPressed = Color(0xFFEA580C);
  static const Color warningSoft = Color(0xFFFFF0E4);
  static const Color warningBorder = Color(0xFFFAC49A);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerPressed = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEEDEE);
  static const Color dangerBorder = Color(0xFFF8B8BD);

  static const Color device = Color(0xFF228FB5);
  static const Color devicePressed = Color(0xFF157492);
  static const Color deviceSoft = Color(0xFFE4F4F7);
  static const Color deviceBorder = Color(0xFFAED9E2);

  static const Color surface = Color(0xFFF4F8F7);
  static const Color surfaceBase = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF5F3);
  static const Color surfaceTint = Color(0xFFE9F4F0);
  static const Color surfacePressed = Color(0xFFDDEAE6);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color onInverse = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color scrim = Color(0x660F172A);

  static const Color primary = brand;
  static const Color primaryContainer = info;
  static const Color primaryDim = success;
  static const Color surfaceContainerLowest = surfaceBase;
  static const Color surfaceContainerLow = surfaceMuted;
  static const Color surfaceContainerHigh = surfacePressed;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textSecondary;
  static const Color error = danger;
  static const Color errorContainer = dangerSoft;
}

class AppSpacing {
  AppSpacing._();

  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double page = 18;
  static const double section = 18;
}

class AppRadii {
  AppRadii._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double sheet = 16;
  static const double appFrame = 24;
  static const double pill = 999;
}

class AppTypography {
  AppTypography._();

  static const List<String> fontFallback = [
    'PingFang SC',
    'Hiragino Sans GB',
    'Microsoft YaHei',
    'Noto Sans SC',
    'Noto Sans CJK SC',
    'Arial Unicode MS',
    'sans-serif',
  ];

  static const TextTheme textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.12,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.16,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.22,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      height: 1.28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: AppColors.textTertiary,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: AppColors.textTertiary,
      letterSpacing: 0,
    ),
  );
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);
}

class AppShadows {
  AppShadows._();

  static final cardShadow = BoxShadow(
    color: AppColors.textPrimary.withValues(alpha: 0.05),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );

  static final elevatedShadow = BoxShadow(
    color: AppColors.textPrimary.withValues(alpha: 0.10),
    blurRadius: 28,
    offset: const Offset(0, 14),
  );

  static final ambientShadow = BoxShadow(
    color: AppColors.brand.withValues(alpha: 0.08),
    blurRadius: 28,
    offset: const Offset(0, 12),
  );

  static final ghostBorder = Border.all(
    color: AppColors.brand.withValues(alpha: 0.16),
    width: 1,
  );
}

class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand, AppColors.info],
  );

  static const LinearGradient commerce = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.commerce, AppColors.warning],
  );

  static const LinearGradient device = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand, AppColors.device, AppColors.info],
  );
}
