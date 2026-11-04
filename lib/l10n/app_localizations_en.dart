// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String intervalLabel(int number) {
    return 'INTERVAL $number';
  }

  @override
  String get addInterval => 'Add an interval';

  @override
  String get removeInterval => 'Delete';

  @override
  String get moveInterval => 'Move';

  @override
  String get mySeries => 'My series';

  @override
  String get settings => 'Settings';

  @override
  String get chronoTab => 'Chrono';

  @override
  String maxIntervals(int max) {
    return '$max intervals maximum';
  }

  @override
  String totalDuration(String duration) {
    return 'Total: $duration';
  }

  @override
  String totalDurationRounds(String total, int rounds, String round) {
    return 'Total: $total  ($rounds × $round)';
  }

  @override
  String get emptyIntervalWarning =>
      'Each interval must last at least 1 second';

  @override
  String get save => 'Save';

  @override
  String get start => 'Start';

  @override
  String get loopOnce => 'Once';

  @override
  String get loopRepeat => 'Repeat x times';

  @override
  String loopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String get fewerRepeats => 'Fewer repeats';

  @override
  String get moreRepeats => 'More repeats';

  @override
  String get interruptedTitle => 'Series interrupted';

  @override
  String get interruptedBody => 'A series was running. Resume it?';

  @override
  String get no => 'No';

  @override
  String get resume => 'Resume';

  @override
  String savedSnack(String name) {
    return '“$name” saved';
  }

  @override
  String updatedSnack(String name) {
    return '“$name” updated';
  }

  @override
  String get minutesUnit => 'min';

  @override
  String get secondsUnit => 's';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get secondsLabel => 'Seconds';

  @override
  String runInterval(int index, int count) {
    return 'INTERVAL $index/$count';
  }

  @override
  String runRound(int round, int rounds) {
    return 'ROUND $round/$rounds';
  }

  @override
  String get paused => 'PAUSED';

  @override
  String nextInterval(String duration) {
    return 'Next: $duration';
  }

  @override
  String get lastInterval => 'Last interval';

  @override
  String get done => 'Done';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get restart => 'Restart';

  @override
  String get newSeries => 'New series';

  @override
  String get stopTitle => 'Stop the series?';

  @override
  String get continueRun => 'Continue';

  @override
  String get back => 'Back';

  @override
  String seriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SERIES',
      one: '1 SERIES',
    );
    return '$_temp0';
  }

  @override
  String get launch => 'Start';

  @override
  String get options => 'Options';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String deletedSnack(String name) {
    return '“$name” deleted';
  }

  @override
  String get undo => 'Undo';

  @override
  String get emptyLibraryTitle => 'No saved series';

  @override
  String get emptyLibraryHint => 'Build a series, then tap “Save”.';

  @override
  String intervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intervals',
      one: '1 interval',
    );
    return '$_temp0';
  }

  @override
  String get saveSeriesTitle => 'Save the series';

  @override
  String get nameHint => 'Workout1';

  @override
  String get replace => 'Replace';

  @override
  String get replaceHelper =>
      'A series already has this name: it will be replaced.';

  @override
  String get nameTaken => 'This name is already used.';

  @override
  String get cancel => 'Cancel';

  @override
  String get languageSection => 'LANGUAGE';

  @override
  String get languageAuto => 'Auto';

  @override
  String languageAutoHint(String language) {
    return 'Auto follows the device language (currently: $language).';
  }

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get soundSection => 'SOUND';

  @override
  String get soundToggle => 'Sounds';

  @override
  String get soundToggleHint =>
      'Countdown beeps, interval changes and end of series.';

  @override
  String get duckingHint =>
      'Your music dips during each sound, then gently comes back (Bluetooth and AirPlay included).';

  @override
  String get soundThemeClassic => 'Classic beep';

  @override
  String get soundThemeBell => 'Soft bell';

  @override
  String get soundThemeMarimba => 'Marimba';

  @override
  String get soundThemePulse => 'Electro pulse';

  @override
  String previewSoundFor(String name) {
    return 'Listen: $name';
  }

  @override
  String get hapticsSection => 'VIBRATIONS';

  @override
  String get hapticsToggle => 'Vibrations';

  @override
  String get hapticsHint =>
      'A vibration comes with beeps, interval changes and the end of the series.';

  @override
  String get paletteSection => 'COLOURS';

  @override
  String get seriesSection => 'SAVED SERIES';

  @override
  String get manageSeries => 'Manage my series';

  @override
  String get manageSeriesHint => 'Start, rename or delete your series.';
}
