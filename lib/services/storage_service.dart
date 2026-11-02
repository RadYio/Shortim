import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/series.dart';
import 'timer_engine.dart';

/// A run persisted so it can be resumed if the app gets killed.
typedef SavedRun = ({Series series, TimerRunState state});

/// Local persistence: the last edited series and the run in progress.
class StorageService {
  static const _draftKey = 'draft_series';
  static const _runKey = 'active_run';

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
}
