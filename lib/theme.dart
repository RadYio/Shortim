import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// UI colour tokens (see CLAUDE.md §1). Brand assets in `assets/logos/` use
/// their own fixed colours (#0A0A0A / #F2F2F0) on purpose.
///
/// Mutable on purpose: [AppPalette] pairs a background with one typography/
/// accent colour, and [AppColors.apply] derives every other token from that
/// single pair. `buildTheme` calls it before building the `ThemeData`, so by
/// the time any widget below `MaterialApp` reads these (most do, directly,
/// rather than through `Theme.of(context)`) they already reflect the
/// current palette — Flutter builds top-down in the same frame.
abstract final class AppColors {
  static Color ink = AppPalette.cloud.background;
  static Color surface = const Color(0xFF0E0E10); // cards, a notch above ink
  static Color surfaceRaised = const Color(0xFF17171A); // dialogs, proxy
  static Color text = AppPalette.cloud.accent;
  static Color brand300 = const Color(0xFFD4D4D8);
  static Color brand400 = const Color(0xFFA1A1AA);
  static Color brand500 = const Color(0xFF71717A);
  static Color brand600 = const Color(0xFF52525B);
  static Color brand700 = const Color(0xFF3F3F46);

  /// Recomputes every token above from [palette]'s background/accent pair.
  static void apply(AppPalette palette) {
    Color mix(double t) => Color.lerp(palette.background, palette.accent, t)!;
    ink = palette.background;
    surface = mix(0.06);
    surfaceRaised = mix(0.10);
    text = palette.accent;
    brand300 = mix(0.72);
    brand400 = mix(0.52);
    brand500 = mix(0.36);
    brand600 = mix(0.24);
    brand700 = mix(0.14);
  }
}

/// A background/typography colour pair selectable in Settings — replaces
/// the old single-hue "accent": font and highlights share [accent], the
/// rest of the UI (surfaces, muted labels, borders) is derived from the mix
/// of the two. Named after current colour-trend vocabulary.
enum AppPalette {
  /// Sporty, energetic: flashy lime on a near-black forest green.
  volt('Volt', Color(0xFF0A130D), Color(0xFFC6FF3D)),

  /// Calm, hazy — 2026's "frosted tints" mood.
  chill('Chill', Color(0xFF0A0D16), Color(0xFF9FB4FF)),

  /// Warm and cozy — Pantone 2025 Colour of the Year, Mocha Mousse.
  mocha('Mocha', Color(0xFF150F0C), Color(0xFFC9966B)),

  /// Minimal and serene — Pantone 2026 Colour of the Year, Cloud Dancer.
  cloud('Cloud', Color(0xFF08080A), Color(0xFFF0EDE5));

  const AppPalette(this.label, this.background, this.accent);

  final String label;
  final Color background;
  final Color accent;
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
  static TextStyle label({Color? color}) => mono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.4,
  ).copyWith(color: color ?? AppColors.brand400);
}

ThemeData buildTheme({AppPalette palette = AppPalette.cloud}) {
  AppColors.apply(palette);
  final accentColor = palette.accent;
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
        side: BorderSide(color: AppColors.brand600),
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
        side: BorderSide(color: AppColors.brand700),
        shape: pill,
        minimumSize: const Size.fromHeight(44),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: AppColors.brand700),
      ),
      // Same default font as the buttons/content inside it — the wordmark
      // (Playfair) is reserved for full-screen headers, never modals.
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      contentTextStyle: TextStyle(fontSize: 15, color: AppColors.brand300),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      actionTextColor: accentColor,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
      shape: StadiumBorder(side: BorderSide(color: AppColors.brand700)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
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
      hintStyle: TextStyle(color: AppColors.brand600),
      helperStyle: TextStyle(color: AppColors.brand400),
      helperMaxLines: 2,
      counterStyle: AppText.mono(fontSize: 11, color: AppColors.brand500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.brand700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
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
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.brand700),
      ),
      textStyle: TextStyle(fontSize: 15, color: AppColors.text),
    ),
  );
}
