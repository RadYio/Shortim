import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/series_library.dart';
import '../services/settings_controller.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/transitions.dart';
import 'library_screen.dart';

/// "Réglages". Unlike the rest of the app it spells everything out. Pops
/// with a [LibraryChoice] when a series was picked from "Gérer mes séries".
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.sounds,
    required this.library,
  });

  final SoundService sounds;
  final SeriesLibrary library;

  Future<void> _preview(SoundTheme theme) async {
    await sounds.init();
    await sounds.setTheme(theme);
    await sounds.intervalChange();
  }

  Future<void> _openLibrary(BuildContext context) async {
    final choice = await Navigator.of(context).push(
      fadeSlideRoute<LibraryChoice>((_) => LibraryScreen(library: library)),
    );
    if (choice != null && context.mounted) Navigator.pop(context, choice);
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: AppColors.brand300,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Text(l10n.settings, style: AppText.wordmark(fontSize: 32)),
              ],
            ),
            _Section(
              label: l10n.languageSection,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AppLanguage>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: AppLanguage.system,
                        label: Text(l10n.languageAuto),
                      ),
                      ButtonSegment(
                        value: AppLanguage.fr,
                        label: Text(l10n.languageFrench),
                      ),
                      ButtonSegment(
                        value: AppLanguage.en,
                        label: Text(l10n.languageEnglish),
                      ),
                    ],
                    selected: {settings.language},
                    onSelectionChanged: (s) =>
                        update((x) => x.copyWith(language: s.single)),
                  ),
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
                  child: IgnorePointer(
                    ignoring: !settings.soundEnabled,
                    child: Column(
                      children: [
                        for (final theme in SoundTheme.values)
                          _ThemeTile(
                            name: _themeName(l10n, theme),
                            selected: theme == settings.soundTheme,
                            previewTooltip: l10n.previewSoundFor(
                              _themeName(l10n, theme),
                            ),
                            onSelect: () {
                              update((x) => x.copyWith(soundTheme: theme));
                              unawaited(_preview(theme));
                            },
                            onPreview: () => unawaited(_preview(theme)),
                          ),
                      ],
                    ),
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
              label: l10n.accentSection,
              children: [
                _AccentPicker(
                  selected: settings.accent,
                  nameOf: (a) => _accentName(l10n, a),
                  onSelect: (a) => update((x) => x.copyWith(accent: a)),
                ),
              ],
            ),
            _Section(
              label: l10n.seriesSection,
              children: [
                _Card(
                  onTap: () => _openLibrary(context),
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
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.brand400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.brand500,
                      ),
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

  static String _accentName(AppLocalizations l10n, AccentColor accent) =>
      switch (accent) {
        AccentColor.cream => l10n.accentCream,
        AccentColor.gold => l10n.accentGold,
        AccentColor.coral => l10n.accentCoral,
        AccentColor.teal => l10n.accentTeal,
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
        style: const TextStyle(fontSize: 13, color: AppColors.brand500),
      ),
    );
  }
}

/// Bordered card, like the interval and saved-series cards.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap, this.selected = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

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
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : AppColors.brand700,
          ),
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
                  style: const TextStyle(
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

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.name,
    required this.selected,
    required this.previewTooltip,
    required this.onSelect,
    required this.onPreview,
  });

  final String name;
  final bool selected;
  final String previewTooltip;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: _Card(
        selected: selected,
        onTap: onSelect,
        child: Row(
          children: [
            // Radio dot that pops in with a slight bounce.
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : AppColors.brand600,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: AppMotion.slow,
                curve: AppMotion.emphasis,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 16))),
            IconButton(
              tooltip: previewTooltip,
              icon: const Icon(Icons.volume_up_outlined, size: 20),
              color: AppColors.brand400,
              onPressed: onPreview,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentPicker extends StatelessWidget {
  const _AccentPicker({
    required this.selected,
    required this.nameOf,
    required this.onSelect,
  });

  final AccentColor selected;
  final String Function(AccentColor) nameOf;
  final ValueChanged<AccentColor> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final accent in AccentColor.values)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Semantics(
                  button: true,
                  selected: accent == selected,
                  label: nameOf(accent),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onSelect(accent),
                    child: AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.brand,
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent == selected
                              ? accent.color
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: accent == selected ? 1 : 0.82,
                        duration: AppMotion.slow,
                        curve: AppMotion.emphasis,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.color,
                          ),
                        ),
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
            nameOf(selected),
            key: ValueKey(selected),
            style: AppText.mono(fontSize: 13, color: AppColors.brand300),
          ),
        ),
      ],
    );
  }
}
