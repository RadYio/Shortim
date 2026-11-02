import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_series.dart';
import '../models/series.dart';
import 'settings_controller.dart';
import 'timer_engine.dart';

/// A run persisted so it can be resumed if the app gets killed.
typedef SavedRun = ({Series series, TimerRunState state});

/// Local persistence: the last edited series, the run in progress, the
/// saved series library and the settings.
class StorageService {
  static const _draftKey = 'draft_series';
  static const _runKey = 'active_run';
  static const _libraryKey = 'saved_series';
  static const _settingsKey = 'settings';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Series?> loadDraft() async {
    final raw = (await _prefs).getString(_draftKey);
    if (raw == null) return null;
    try {
      return Series.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ignoring corrupted draft: $e');
      return null;
    }
  }

  Future<void> saveDraft(Series series) async =>
      (await _prefs).setString(_draftKey, jsonEncode(series.toJson()));

  Future<SavedRun?> loadRun() async {
    final raw = (await _prefs).getString(_runKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        series: Series.fromJson(json['series'] as Map<String, dynamic>),
        state: TimerRunState.fromJson(json['state'] as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('Ignoring corrupted run: $e');
      await clearRun();
      return null;
    }
  }

  Future<void> saveRun(Series series, TimerRunState state) async =>
      (await _prefs).setString(
        _runKey,
        jsonEncode({'series': series.toJson(), 'state': state.toJson()}),
      );

  Future<void> clearRun() async => (await _prefs).remove(_runKey);

  /// Saved series as a JSON list. A corrupted entry is skipped on its own
  /// rather than losing the whole library.
  Future<List<SavedSeries>> loadLibrary() async {
    final raw = (await _prefs).getString(_libraryKey);
    if (raw == null) return [];
    final List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (e) {
      debugPrint('Ignoring corrupted library: $e');
      return [];
    }
    final library = <SavedSeries>[];
    for (final entry in list) {
      try {
        library.add(SavedSeries.fromJson(entry as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Ignoring corrupted saved series: $e');
      }
    }
    return library;
  }

  Future<void> saveLibrary(List<SavedSeries> library) async =>
      (await _prefs).setString(
        _libraryKey,
        jsonEncode([for (final s in library) s.toJson()]),
      );

  Future<AppSettings> loadSettings() async {
    final raw = (await _prefs).getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ignoring corrupted settings: $e');
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async =>
      (await _prefs).setString(_settingsKey, jsonEncode(settings.toJson()));
}
