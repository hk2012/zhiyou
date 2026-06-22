import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => lightThemeFor(const Locale('zh'));

  static ThemeData lightThemeFor(Locale locale) {
    final fontFamily = locale.languageCode == 'ko' ? 'NotoSansKR' : null;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      fontFamilyFallback: AppTypography.fontFallback,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        onPrimary: AppColors.onInverse,
        primaryContainer: AppColors.brandSoft,
        onPrimaryContainer: AppColors.brandPressed,
        secondary: AppColors.info,
        onSecondary: AppColors.onInverse,
        secondaryContainer: AppColors.infoSoft,
        onSecondaryContainer: AppColors.infoPressed,
        tertiary: AppColors.commerce,
        onTertiary: AppColors.onInverse,
        tertiaryContainer: AppColors.commerceSoft,
        onTertiaryContainer: AppColors.commercePressed,
        error: AppColors.danger,
        onError: AppColors.onInverse,
        errorContainer: AppColors.dangerSoft,
        onErrorContainer: AppColors.dangerPressed,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
        scrim: AppColors.scrim,
      ),
    );

    return base.copyWith(
      primaryColor: AppColors.brand,
      textTheme: fontFamily == null
          ? AppTypography.textTheme
          : AppTypography.textTheme.apply(fontFamily: fontFamily),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaised,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.onInverse,
          disabledBackgroundColor: AppColors.surfacePressed,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppColors.surfaceRaised,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.surfacePressed,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            side: const BorderSide(color: AppColors.border),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brandBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onInverse,
        elevation: 8,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 8,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textDisabled,
          fontSize: 14,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.dangerBorder),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedColor: AppColors.brandSoft,
        disabledColor: AppColors.surfacePressed,
        deleteIconColor: AppColors.textTertiary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.brand,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: AppColors.onInverse,
          fontSize: 13,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceRaised,
        modalBackgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        elevation: 0,
        modalElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandSoft,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.brand : AppColors.textSecondary,
            fontSize: 11,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.brand : AppColors.textSecondary,
            size: 23,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: AppColors.surfacePressed,
        circularTrackColor: AppColors.surfacePressed,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;

  static ThemeData darkThemeFor(Locale locale) => lightThemeFor(locale);
}
