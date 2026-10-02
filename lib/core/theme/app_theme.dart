import 'package:flutter/material.dart';
import 'app_constants.dart';

/// High-contrast theme (black/yellow/white) satisfying WCAG AA contrast ratios.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          error: AppColors.error,
          onError: AppColors.onError,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: AppColors.onBackground,
            fontSize: 16,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            color: AppColors.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(72, 72),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 32,
        ),
        dividerColor: AppColors.border,
        useMaterial3: true,
      );
}
