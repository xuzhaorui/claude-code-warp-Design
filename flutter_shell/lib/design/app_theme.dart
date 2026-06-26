import 'package:flutter/material.dart';

import 'app_design_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Warehouse Material theme assembled from design tokens.
///
/// All visual constants are resolved from [AppDesignColors], [AppTextStyles],
/// [AppSpacing], and [AppRadii]. No Material default colors leak into the
/// product identity.
class AppTheme {
  AppTheme._();

  /// The single [ThemeData] used by [MaterialApp].
  ///
  /// Sets scaffold background, card defaults, text theme, button themes,
  /// input decoration, and bottom sheet shape — all from design tokens.
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppDesignColors.primary,
      onPrimary: AppDesignColors.textPrimary,
      secondary: AppDesignColors.primarySoft,
      onSecondary: AppDesignColors.textPrimary,
      surface: AppDesignColors.surface,
      onSurface: AppDesignColors.textPrimary,
      surfaceContainerHighest: AppDesignColors.surfaceMuted,
      outline: AppDesignColors.borderMuted,
      error: Color(0xFFDC2626),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDesignColors.background,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        headlineLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        labelLarge: AppTextStyles.label,
        bodySmall: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDesignColors.background,
        foregroundColor: AppDesignColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppDesignColors.surface,
        surfaceTintColor: AppDesignColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadii.lg),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignColors.primary,
          foregroundColor: AppDesignColors.textPrimary,
          textStyle: AppTextStyles.label,
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppDesignColors.primarySoft,
          foregroundColor: AppDesignColors.textPrimary,
          textStyle: AppTextStyles.label,
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesignColors.surfaceMuted,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(AppRadii.md),
          borderSide: const BorderSide(color: AppDesignColors.primary),
        ),
        labelStyle: AppTextStyles.body.copyWith(
          color: AppDesignColors.textSecondary,
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: AppDesignColors.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDesignColors.surface,
        surfaceTintColor: AppDesignColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: AppRadii.xl,
            topRight: AppRadii.xl,
          ),
        ),
        modalBarrierColor: AppDesignColors.overlay,
      ),
      dividerTheme: const DividerThemeData(
        color: AppDesignColors.borderMuted,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
