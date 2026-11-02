import 'package:flutter/widgets.dart';

import '../models/series.dart';
import '../models/timer_interval.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// French when the device's preferred language is French, English otherwise.
Locale resolveDeviceLocale(List<Locale>? device) =>
    device != null && device.isNotEmpty && device.first.languageCode == 'fr'
    ? const Locale('fr')
    : const Locale('en');

/// One-line summary, e.g. "8 intervalles · 12:30 · ×3": one pass through
/// the intervals, then "×N" when the series repeats.
String seriesSummary(AppLocalizations l10n, Series series) => [
  l10n.intervalCount(series.intervals.length),
  formatDuration(series.roundDuration),
  if (series.rounds > 1) '×${series.rounds}',
].join(' · ');
