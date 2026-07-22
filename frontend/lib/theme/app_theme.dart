import 'package:flutter/material.dart';

/// Central color and text style tokens, matching the purple brand used
/// throughout the mockups (home header, assistant card, chat bubbles,
/// primary buttons).
class AppColors {
  static const purple = Color(0xFF7B6FE0);
  static const purpleDark = Color(0xFF534AB7);
  static const purpleLight = Color(0xFFEEEDFE);

  static const safe = Color(0xFF3B6D11);
  static const safeBg = Color(0xFFEAF3DE);
  static const limit = Color(0xFF854F0B);
  static const limitBg = Color(0xFFFAEEDA);
  static const avoid = Color(0xFF791F1F);
  static const avoidBg = Color(0xFFFCEBEB);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textMuted = Color(0xFF9C9C9C);
  static const border = Color(0xFFE5E3ED);
  static const surface = Colors.white;
  static const pageBg = Color(0xFFFBFAFF);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        primary: AppColors.purple,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 0.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
