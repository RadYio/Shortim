import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/series_library.dart';
import '../services/settings_controller.dart';
import '../services/sound_service.dart';
import '../theme.dart';

/// "Réglages". Unlike the rest of the app it spells everything out. Lives
/// inside the shell's persistent bottom menu: [onOpenLibrary] switches to
/// the "Mes séries" tab. No back button — the bottom menu is the only nav.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.sounds,
    required this.library,
    required this.onOpenLibrary,
  });

  final SoundService sounds;
  final SeriesLibrary library;
  final VoidCallback onOpenLibrary;

  Future<void> _preview(SoundTheme theme) async {
    await sounds.init();
    await sounds.setTheme(theme);
    await sounds.intervalChange();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = SettingsScope.of(context);
    final settings = controller.settings;
    void update(AppSettings Function(AppSettings) change) =>
        unawaited(controller.update(change));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, kBottomBarReserve),
          children: [
            Text(l10n.settings, style: AppText.wordmark(fontSize: 32)),
            _Section(
              label: l10n.paletteSection,
              children: [
                _PalettePicker(
                  selected: settings.palette,
                  onSelect: (p) => update((x) => x.copyWith(palette: p)),
                ),
              ],
            ),
            _Section(
              label: l10n.languageSection,
              children: [
                DropdownButtonFormField<AppLanguage>(
                  initialValue: settings.language,
                  dropdownColor: AppColors.surfaceRaised,
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.system,
                      child: Text(l10n.languageAuto),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.fr,
                      child: Text(l10n.languageFrench),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.en,
                      child: Text(l10n.languageEnglish),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) update((x) => x.copyWith(language: v));
                  },
                ),
                _Hint(l10n.languageAutoHint(_deviceLanguageName(l10n))),
              ],
            ),
            _Section(
              label: l10n.soundSection,
              children: [
                _Toggle(
                  title: l10n.soundToggle,
                  subtitle: l10n.soundToggleHint,
                  value: settings.soundEnabled,
                  onChanged: (v) => update((x) => x.copyWith(soundEnabled: v)),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: settings.soundEnabled ? 1 : 0.4,
                  duration: AppMotion.base,
                  curve: AppMotion.brand,
                  child: DropdownButtonFormField<SoundTheme>(
                    initialValue: settings.soundTheme,
                    dropdownColor: AppColors.surfaceRaised,
                    items: [
                      for (final theme in SoundTheme.values)
                        DropdownMenuItem(
                          value: theme,
                          child: Text(_themeName(l10n, theme)),
                        ),
                    ],
                    onChanged: !settings.soundEnabled
                        ? null
                        : (theme) {
                            if (theme == null) return;
                            update((x) => x.copyWith(soundTheme: theme));
                            unawaited(_preview(theme));
                          },
                  ),
                ),
                _Hint(l10n.duckingHint),
              ],
            ),
            _Section(
              label: l10n.hapticsSection,
              children: [
                _Toggle(
                  title: l10n.hapticsToggle,
                  subtitle: l10n.hapticsHint,
                  value: settings.haptics,
                  onChanged: (v) => update((x) => x.copyWith(haptics: v)),
                ),
              ],
            ),
            _Section(
              label: l10n.seriesSection,
              children: [
                _Card(
                  onTap: onOpenLibrary,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.manageSeries,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.manageSeriesHint,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.brand400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.brand500),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Name of the language "Auto" currently resolves to.
  static String _deviceLanguageName(AppLocalizations l10n) =>
      resolveDeviceLocale(
            WidgetsBinding.instance.platformDispatcher.locales,
          ).languageCode ==
          'fr'
      ? l10n.languageFrench
      : l10n.languageEnglish;

  static String _themeName(AppLocalizations l10n, SoundTheme theme) =>
      switch (theme) {
        SoundTheme.classic => l10n.soundThemeClassic,
        SoundTheme.bell => l10n.soundThemeBell,
        SoundTheme.marimba => l10n.soundThemeMarimba,
        SoundTheme.pulse => l10n.soundThemePulse,
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppText.label()),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: AppColors.brand500),
      ),
    );
  }
}

/// Bordered card, like the interval and saved-series cards.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.brand,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brand700),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.brand400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Bubble split diagonally (top-right → bottom-left): background colour on
/// one half, typography/accent colour on the other — exactly the pairing
/// that choosing a palette changes, instead of a single accent dot.
class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.selected, required this.onSelect});

  final AppPalette selected;
  final ValueChanged<AppPalette> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final palette in AppPalette.values)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Semantics(
                  button: true,
                  selected: palette == selected,
                  label: palette.label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onSelect(palette),
                    child: AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.brand,
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette == selected
                              ? palette.accent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: palette == selected ? 1 : 0.82,
                        duration: AppMotion.slow,
                        curve: AppMotion.emphasis,
                        child: _PaletteBubble(palette: palette),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppMotion.base,
          child: Text(
            selected.label,
            key: ValueKey(selected),
            style: AppText.mono(fontSize: 13, color: AppColors.brand300),
          ),
        ),
      ],
    );
  }
}

/// The diagonally-split preview circle itself.
class _PaletteBubble extends StatelessWidget {
  const _PaletteBubble({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: palette.background),
          // Lower-right half (the diagonal cut) carries both accents
          // stacked, not one flat tint — reads as a real palette.
          ClipPath(
            clipper: _DiagonalClipper(),
            child: Column(
              children: [
                Expanded(child: ColoredBox(color: palette.accent)),
                Expanded(child: ColoredBox(color: palette.accent2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuts from the top-right corner to the bottom-left one.
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
