import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _fontFamily = 'ZCOOLXiaoWei';
  static const _fontFallback = [
    'ZCOOLXiaoWei',
    'Songti SC',
    'STSong',
    'Kaiti SC',
    'STKaiti',
    'Source Han Serif SC',
    'Noto Serif CJK SC',
    'Noto Sans CJK SC',
    'PingFang SC',
    'Hiragino Sans GB',
    'Microsoft YaHei',
    'Arial Unicode MS',
    'serif',
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      // Theming Setup
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
      ),

      // TextTheme using Editorial Clarity rules
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
        labelMedium: TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),

      // "The Layering Principle" & "Organic Theme" Cards
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(), // "Organic Theme", 1.5rem / Circle
      ),

      // Primary Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
      ),
    );
  }
}
