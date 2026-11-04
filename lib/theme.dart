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
  static Color ink = AppPalette.sprint.background;
  static Color surface = const Color(0xFF0E0E10); // cards, a notch above ink
  static Color surfaceRaised = const Color(0xFF17171A); // dialogs, proxy
  static Color text = AppPalette.sprint.text;
  static Color accent2 = AppPalette.sprint.accent2;
  static Color brand300 = const Color(0xFFD4D4D8);
  static Color brand400 = const Color(0xFFA1A1AA);
  static Color brand500 = const Color(0xFF71717A);
  static Color brand600 = const Color(0xFF52525B);
  static Color brand700 = const Color(0xFF3F3F46);

  /// Recomputes every token above from [palette]'s colours. Unlike the old
  /// scheme (always mixing toward near-black `background`), this derives the
  /// neutral ramp from `muted` → `text`, which are chosen per-palette to
  /// already sit at the right end of the brightness scale — so this reads
  /// correctly for both dark palettes (sprint, gymFloor) and light ones
  /// (endurance, flow) without any brightness-specific branching here.
  static void apply(AppPalette palette) {
    Color mix(double t) => Color.lerp(palette.muted, palette.text, t)!;
    ink = palette.background;
    text = palette.text;
    accent2 = palette.accent2;
    surface = palette.muted;
    surfaceRaised = Color.lerp(palette.muted, palette.text, 0.10)!;
    brand300 = mix(0.80);
    brand400 = mix(0.58);
    brand500 = mix(0.38);
    brand600 = mix(0.18);
    brand700 = Color.lerp(palette.background, palette.muted, 0.55)!;
  }
}

/// A 5-role palette selectable in Settings: [background]/[muted] are the two
/// surface shades, [accent] drives typography/numbers/links, [accent2] drives
/// actions (the primary button, selections, switches), and [text] is the
/// dedicated readable body-text colour. Each palette also carries its own
/// [brightness] — unlike the old scheme, these are genuinely different
/// palettes rather than variations on one near-black background, and two of
/// them (endurance, flow) are light.
enum AppPalette {
  /// Dark & energetic: acid lime numbers with a hot-coral call to action,
  /// on a near-black background.
  sprint(
    'Sprint',
    Brightness.dark,
    Color(0xFF0D0D0D),
    Color(0xFF1C1C1C),
    Color(0xFFC8FF00),
    Color(0xFFFF5C39),
    Color(0xFFF2F2F2),
  ),

  /// Light & crisp: deep navy numbers with a punchy orange call to action,
  /// on a clean white background.
  endurance(
    'Endurance',
    Brightness.light,
    Color(0xFFFFFFFF),
    Color(0xFFEDF1F6),
    Color(0xFF1D3557),
    Color(0xFFFF7B00),
    Color(0xFF13233A),
  ),

  /// Light & warm — sage green numbers with a terracotta call to action,
  /// on a soft cream background.
  flow(
    'Flow',
    Brightness.light,
    Color(0xFFF8F6F1),
    Color(0xFFE7E3D9),
    Color(0xFF6B8F71),
    Color(0xFFD08C60),
    Color(0xFF2B2F2A),
  ),

  /// Dark & crisp — court blue numbers with a gold call to action, on a
  /// charcoal background.
  gymFloor(
    'Gym Floor',
    Brightness.dark,
    Color(0xFF121417),
    Color(0xFF1F2328),
    Color(0xFF2D9CDB),
    Color(0xFFF2C94C),
    Color(0xFFE8EAED),
  );

  const AppPalette(
    this.label,
    this.brightness,
    this.background,
    this.muted,
    this.accent,
    this.accent2,
    this.text,
  );

  final String label;
  final Brightness brightness;
  final Color background;
  final Color muted;
  final Color accent;
  final Color accent2;
  final Color text;
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

/// Relative luminance contrast ratio between two colours (WCAG formula).
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final brightest = la > lb ? la : lb;
  final darkest = la > lb ? lb : la;
  return (brightest + 0.05) / (darkest + 0.05);
}

/// Picks whichever of pure black/white reads better on [background] — used
/// for text/icons drawn directly on a saturated accent colour, since a
/// palette's `ink` (its *screen* background) only happens to double as a
/// legible foreground by coincidence of brightness, not by design: for a
/// light palette with a dark-but-not-black accent2 (e.g. `endurance`'s
/// orange), `ink` (white) can fail contrast where black would not.
Color _onColorFor(Color background) {
  final onWhite = _contrastRatio(Colors.white, background);
  final onBlack = _contrastRatio(Colors.black, background);
  return onWhite >= onBlack ? Colors.white : Colors.black;
}

ThemeData buildTheme({AppPalette palette = AppPalette.sprint}) {
  AppColors.apply(palette);
  final accentColor = palette.accent;
  final actionColor = palette.accent2;
  final isDark = palette.brightness == Brightness.dark;
  final onAccent = _onColorFor(accentColor);
  final onAction = _onColorFor(actionColor);
  const pill = StadiumBorder();
  const buttonText = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  final scheme = isDark
      ? ColorScheme.dark(
          primary: actionColor,
          onPrimary: onAction,
          secondary: accentColor,
          onSecondary: onAccent,
          surface: AppColors.ink,
          onSurface: AppColors.text,
          surfaceContainerHighest: AppColors.surfaceRaised,
          outline: AppColors.brand700,
          outlineVariant: AppColors.brand700,
        )
      : ColorScheme.light(
          primary: actionColor,
          onPrimary: onAction,
          secondary: accentColor,
          onSecondary: onAccent,
          surface: AppColors.ink,
          onSurface: AppColors.text,
          surfaceContainerHighest: AppColors.surfaceRaised,
          outline: AppColors.brand700,
          outlineVariant: AppColors.brand700,
        );
  final base = ThemeData(
    brightness: palette.brightness,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: actionColor,
        foregroundColor: onAction,
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
        foregroundColor: actionColor,
        shape: pill,
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.brand300,
        selectedForegroundColor: onAction,
        selectedBackgroundColor: actionColor,
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
      actionTextColor: actionColor,
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
        borderSide: BorderSide(color: actionColor),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: actionColor,
      selectionColor: actionColor.withValues(alpha: 0.3),
      selectionHandleColor: actionColor,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? onAction
            : AppColors.brand400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? actionColor
            : AppColors.surfaceRaised,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? actionColor
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
