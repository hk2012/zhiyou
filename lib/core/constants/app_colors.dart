import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Jianghu Ink Lake Palette
  static const Color primary = Color(0xFF0E3A3A);
  static const Color primaryContainer = Color(0xFF1F5A5A);
  static const Color primaryDim = Color(0xFF40746E);

  static const Color surface = Color(0xFFF7F1E5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1E7D2);
  static const Color surfaceContainerHigh = Color(0xFFE6EEE8);

  static const Color onSurface = Color(0xFF16312F);
  static const Color onSurfaceVariant = Color(0xFF425B56);

  static const Color error = Color(0xFFCB5A3E);
  static const Color errorContainer = Color(0xFFF0D8CC);
}

class AppShadows {
  AppShadows._();

  // "Ambient Shadow" for floating elements (blur 24px, y 8px, opacity 4%)
  static final ambientShadow = BoxShadow(
    color: AppColors.primary.withValues(alpha: 0.08),
    blurRadius: 28,
    offset: const Offset(0, 12),
  );

  // Ghost border fallback for thumbnails
  static final ghostBorder = Border.all(
    color: AppColors.primary.withValues(alpha: 0.16),
    width: 1,
  );
}
