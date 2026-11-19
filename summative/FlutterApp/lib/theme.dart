import 'package:flutter/material.dart';

/// Colours and shapes for the app. The palette follows the Sema app:
/// azure brand colour, cool grey neutrals, flat surfaces separated by borders.
abstract final class AppColors {
  static const azure = Color(0xFF0067FF); // brand: buttons, focus, accents
  static const azureDeep = Color(0xFF0047B3);
  static const azureMist = Color(0xFFE6F0FF); // soft tint behind result text
  static const white = Color(0xFFFFFFFF);
  static const snow = Color(0xFFF7F9FC); // text field fill
  static const cloud = Color(0xFFE6EAF0); // borders
  static const ink = Color(0xFF0B0F17); // main text
  static const slate = Color(0xFF64708A); // hints and helper text
  static const crimson = Color(0xFFB91C1C); // errors
  static const crimsonMist = Color(0xFFFDE8E8);
}

abstract final class AppTheme {
  static const _fieldRadius = BorderRadius.all(Radius.circular(14));
  static const cardRadius = BorderRadius.all(Radius.circular(16));

  static ThemeData light() {
    const border = OutlineInputBorder(
      borderRadius: _fieldRadius,
      borderSide: BorderSide(color: AppColors.cloud),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.azure).copyWith(
        primary: AppColors.azure,
        onPrimary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        error: AppColors.crimson,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.snow,
        labelStyle: const TextStyle(color: AppColors.slate),
        hintStyle: const TextStyle(color: AppColors.slate),
        helperStyle: const TextStyle(color: AppColors.slate, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.azure, width: 1.6)),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.crimson)),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.crimson, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.azure,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: cardRadius),
          elevation: 0,
        ),
      ),
    );
  }
}
