import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// UI colour tokens (see CLAUDE.md §1). Brand assets in `assets/logos/` use
/// their own fixed colours (#0A0A0A / #F2F2F0) on purpose.
abstract final class AppColors {
  static const ink = Color(0xFF050506);
  static const surface = Color(0xFF0E0E10); // cards, a notch above ink
  static const surfaceRaised = Color(0xFF17171A); // dialogs, drag proxy
  static const cream = Color(0xFFF4F1EA);
  static const text = Color(0xFFF7F7F8);
  static const brand300 = Color(0xFFD4D4D8);
  static const brand400 = Color(0xFFA1A1AA);
  static const brand500 = Color(0xFF71717A);
  static const brand600 = Color(0xFF52525B);
  static const brand700 = Color(0xFF3F3F46);
}

/// Accent colours selectable in Settings. Cream is the default.
enum AccentColor {
  cream(AppColors.cream),
  gold(Color(0xFFC9A35A)),
  coral(Color(0xFFE8846B)),
  teal(Color(0xFF4FB6A3));

  const AccentColor(this.color);

  final Color color;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 520);

  /// Soft ease-out for most transitions.
  static const brand = Cubic(.22, 1, .36, 1);

  /// Slight overshoot for micro-interactions that should feel alive.
  static const emphasis = Cubic(.34, 1.56, .64, 1);
}

/// Digits that keep the same width, so the countdown does not wobble.
const tabularFigures = [FontFeature.tabularFigures()];

/// Space every screen must reserve at the bottom so its content never sits
/// under the persistent floating menu bar drawn by `AppShell`.
const kBottomBarReserve = 92.0;

/// Shows [content] in a SnackBar lifted above the persistent floating menu
/// bar, so it never visually collides with (or blocks taps on) it.
void showAppSnackBar(
  BuildContext context,
  String content, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, kBottomBarReserve + 12),
        content: Text(content),
        action: action,
      ),
    );
}

abstract final class AppText {
  /// Playfair Display wordmark (brand screens only).
  static TextStyle wordmark({double fontSize = 30, Color? color}) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.04 * fontSize,
        color: color ?? AppColors.text,
        height: 1.1,
      );

  /// JetBrains Mono with tabular figures, for durations and the countdown.
  static TextStyle mono({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.text,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabularFigures,
  );

  /// Small uppercase mono eyebrow ("INTERVALLE 3/8"). Callers pass text
  /// already in capitals.
  static TextStyle label({Color color = AppColors.brand400}) => mono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.4,
  ).copyWith(color: color);
}

ThemeData buildTheme({AccentColor accent = AccentColor.cream}) {
  final accentColor = accent.color;
  const pill = StadiumBorder();
  const buttonText = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: accentColor,
      onPrimary: AppColors.ink,
      secondary: accentColor,
      onSecondary: AppColors.ink,
      surface: AppColors.ink,
      onSurface: AppColors.text,
      surfaceContainerHighest: AppColors.surfaceRaised,
      outline: AppColors.brand700,
      outlineVariant: AppColors.brand700,
    ),
    scaffoldBackgroundColor: AppColors.ink,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.brand700,
        disabledForegroundColor: AppColors.brand500,
        minimumSize: const Size.fromHeight(56),
        shape: pill,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.brand600),
        minimumSize: const Size.fromHeight(56),
        shape: pill,
        textStyle: buttonText.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        shape: pill,
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.brand300,
        selectedForegroundColor: AppColors.ink,
        selectedBackgroundColor: accentColor,
        side: const BorderSide(color: AppColors.brand700),
        shape: pill,
        minimumSize: const Size.fromHeight(44),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: AppColors.brand700),
      ),
      // Same default font as the buttons/content inside it — the wordmark
      // (Playfair) is reserved for full-screen headers, never modals.
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 15,
        color: AppColors.brand300,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      actionTextColor: accentColor,
      contentTextStyle: const TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.brand700)),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: TextStyle(color: AppColors.text, fontSize: 13),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentColor,
      linearTrackColor: AppColors.brand700,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.brand600),
      helperStyle: const TextStyle(color: AppColors.brand400),
      helperMaxLines: 2,
      counterStyle: AppText.mono(fontSize: 11, color: AppColors.brand500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.brand700),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.brand700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: accentColor),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accentColor,
      selectionColor: accentColor.withValues(alpha: 0.3),
      selectionHandleColor: accentColor,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.ink
            : AppColors.brand400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accentColor
            : AppColors.surfaceRaised,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accentColor
            : AppColors.brand600,
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.brand700),
      ),
      textStyle: TextStyle(fontSize: 15, color: AppColors.text),
    ),
  );
}
