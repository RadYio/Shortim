import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF0A1A33);
  static const navyLight = Color(0xFF142A4D);
  static const white = Colors.white;
  static const muted = Color(0xB3FFFFFF); // 70 % white
  static const faint = Color(0x40FFFFFF); // 25 % white
}

/// Digits that keep the same width, so the countdown does not wobble.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildTheme() {
  const shape = StadiumBorder();
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.navy,
      secondary: AppColors.white,
      onSecondary: AppColors.navy,
      surface: AppColors.navy,
      onSurface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.navy,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        disabledBackgroundColor: AppColors.faint,
        disabledForegroundColor: AppColors.navy,
        minimumSize: const Size.fromHeight(56),
        shape: shape,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.white, width: 1.5),
        minimumSize: const Size.fromHeight(56),
        shape: shape,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.white,
        selectedForegroundColor: AppColors.navy,
        selectedBackgroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.white),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.navyLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.faint),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.white,
      contentTextStyle: TextStyle(color: AppColors.navy),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
