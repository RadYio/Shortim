import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'storage_service.dart';

/// UI language: follow the device, or a manual override.
enum AppLanguage {
  system(null),
  fr(Locale('fr')),
  en(Locale('en'));

  const AppLanguage(this.locale);

  /// Null means "follow the device".
  final Locale? locale;
}

/// Selectable sound themes; each one is a folder in `assets/sounds/`.
enum SoundTheme { classic, bell, marimba, pulse }

/// User preferences, persisted as JSON.
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.system,
    this.soundEnabled = true,
    this.soundTheme = SoundTheme.classic,
    this.haptics = true,
    this.palette = AppPalette.sprint,
  });

  final AppLanguage language;
  final bool soundEnabled;
  final SoundTheme soundTheme;
  final bool haptics;
  final AppPalette palette;

  AppSettings copyWith({
    AppLanguage? language,
    bool? soundEnabled,
    SoundTheme? soundTheme,
    bool? haptics,
    AppPalette? palette,
  }) => AppSettings(
    language: language ?? this.language,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    soundTheme: soundTheme ?? this.soundTheme,
    haptics: haptics ?? this.haptics,
    palette: palette ?? this.palette,
  );

  Map<String, Object> toJson() => {
    'language': language.name,
    'soundEnabled': soundEnabled,
    'soundTheme': soundTheme.name,
    'haptics': haptics,
    'palette': palette.name,
  };

  /// Unknown or missing values fall back to the defaults one by one.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    const d = AppSettings();
    return AppSettings(
      language: byName(AppLanguage.values, json['language'], d.language),
      soundEnabled: json['soundEnabled'] as bool? ?? d.soundEnabled,
      soundTheme: byName(SoundTheme.values, json['soundTheme'], d.soundTheme),
      haptics: json['haptics'] as bool? ?? d.haptics,
      palette: byName(AppPalette.values, json['palette'], d.palette),
    );
  }
}

/// Holds the current [AppSettings] and writes every change through.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage);

  final StorageService _storage;
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _storage.loadSettings();
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings) change) async {
    final next = change(_settings);
    _settings = next;
    notifyListeners();
    await _storage.saveSettings(next);
  }
}

/// Exposes the [SettingsController] to the widget tree.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController super.notifier,
    required super.child,
  });

  /// Rebuilds the caller when settings change.
  static SettingsController of(BuildContext context) => maybeOf(context)!;

  static SettingsController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.notifier;
}
