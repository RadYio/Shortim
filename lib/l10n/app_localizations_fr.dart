// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String intervalLabel(int number) {
    return 'INTERVALLE $number';
  }

  @override
  String get addInterval => 'Ajouter un intervalle';

  @override
  String get removeInterval => 'Supprimer';

  @override
  String get moveInterval => 'Déplacer';

  @override
  String get mySeries => 'Mes séries';

  @override
  String get settings => 'Réglages';

  @override
  String get chronoTab => 'Chrono';

  @override
  String get onboardWelcomeTitle => 'Bienvenue dans Shortim';

  @override
  String get onboardWelcomeSubtitle =>
      'Crée une série de minuteurs sur-mesure et lance-la en quelques secondes.';

  @override
  String get onboardStart => 'Commencer';

  @override
  String get onboardCategoryTitle => 'Quel type de séance ?';

  @override
  String get onboardCategorySubtitle =>
      'On te prépare une première série adaptée.';

  @override
  String get onboardHiit => 'HIIT';

  @override
  String get onboardHiitHint => '8 tours · 20 s effort / 10 s repos';

  @override
  String get onboardStretch => 'Étirements';

  @override
  String get onboardStretchHint => '6 positions · 30 s chacune';

  @override
  String get onboardBreathing => 'Respiration';

  @override
  String get onboardBreathingHint => '5 cycles · inspire / retiens / expire';

  @override
  String get onboardCustom => 'Perso';

  @override
  String get onboardCustomHint => 'Un minuteur simple, à régler toi-même';

  @override
  String get onboardResultTitle => 'Ta première série est prête';

  @override
  String get onboardStartNow => 'Démarrer maintenant';

  @override
  String get onboardEditFirst => 'Modifier d\'abord';

  @override
  String maxIntervals(int max) {
    return '$max intervalles maximum';
  }

  @override
  String totalDuration(String duration) {
    return 'Durée totale : $duration';
  }

  @override
  String totalDurationRounds(String total, int rounds, String round) {
    return 'Durée totale : $total  ($rounds × $round)';
  }

  @override
  String get emptyIntervalWarning =>
      'Chaque intervalle doit durer au moins 1 seconde';

  @override
  String get save => 'Enregistrer';

  @override
  String get start => 'Démarrer';

  @override
  String get loopOnce => '1 fois';

  @override
  String get loopRepeat => 'Répéter x fois';

  @override
  String loopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: '1 fois',
    );
    return '$_temp0';
  }

  @override
  String get fewerRepeats => 'Moins de répétitions';

  @override
  String get moreRepeats => 'Plus de répétitions';

  @override
  String get interruptedTitle => 'Série interrompue';

  @override
  String get interruptedBody => 'Une série était en cours. La reprendre ?';

  @override
  String get no => 'Non';

  @override
  String get resume => 'Reprendre';

  @override
  String savedSnack(String name) {
    return '« $name » enregistrée';
  }

  @override
  String updatedSnack(String name) {
    return '« $name » mise à jour';
  }

  @override
  String get minutesUnit => 'min';

  @override
  String get secondsUnit => 's';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get secondsLabel => 'Secondes';

  @override
  String runInterval(int index, int count) {
    return 'INTERVALLE $index/$count';
  }

  @override
  String runRound(int round, int rounds) {
    return 'TOUR $round/$rounds';
  }

  @override
  String get paused => 'EN PAUSE';

  @override
  String nextInterval(String duration) {
    return 'Suivant : $duration';
  }

  @override
  String get lastInterval => 'Dernier intervalle';

  @override
  String get done => 'Terminé';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Arrêter';

  @override
  String get restart => 'Relancer';

  @override
  String get newSeries => 'Nouvelle série';

  @override
  String get stopTitle => 'Arrêter la série ?';

  @override
  String get continueRun => 'Continuer';

  @override
  String get back => 'Retour';

  @override
  String seriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SÉRIES',
      one: '1 SÉRIE',
    );
    return '$_temp0';
  }

  @override
  String get launch => 'Lancer';

  @override
  String get options => 'Options';

  @override
  String get rename => 'Renommer';

  @override
  String get delete => 'Supprimer';

  @override
  String deletedSnack(String name) {
    return '« $name » supprimée';
  }

  @override
  String get undo => 'Annuler';

  @override
  String get emptyLibraryTitle => 'Aucune série enregistrée';

  @override
  String get emptyLibraryHint =>
      'Composez une série puis touchez « Enregistrer ».';

  @override
  String intervalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intervalles',
      one: '1 intervalle',
    );
    return '$_temp0';
  }

  @override
  String get saveSeriesTitle => 'Enregistrer la série';

  @override
  String get nameHint => 'Muscu1';

  @override
  String get replace => 'Remplacer';

  @override
  String get replaceHelper =>
      'Une série porte déjà ce nom : elle sera remplacée.';

  @override
  String get nameTaken => 'Ce nom est déjà utilisé.';

  @override
  String get cancel => 'Annuler';

  @override
  String get languageSection => 'LANGUE';

  @override
  String get languageAuto => 'Auto';

  @override
  String languageAutoHint(String language) {
    return 'Auto suit la langue de l\'appareil (actuellement : $language).';
  }

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get soundSection => 'SON';

  @override
  String get soundToggle => 'Sons';

  @override
  String get soundToggleHint =>
      'Bips du compte à rebours, changement d\'intervalle et fin de série.';

  @override
  String get duckingHint =>
      'Votre musique baisse le temps de chaque son, puis remonte doucement (y compris en Bluetooth et AirPlay).';

  @override
  String get soundThemeClassic => 'Bip classique';

  @override
  String get soundThemeBell => 'Cloche douce';

  @override
  String get soundThemeMarimba => 'Marimba';

  @override
  String get soundThemePulse => 'Pulse électro';

  @override
  String previewSoundFor(String name) {
    return 'Écouter : $name';
  }

  @override
  String get hapticsSection => 'VIBRATIONS';

  @override
  String get hapticsToggle => 'Vibrations';

  @override
  String get hapticsHint =>
      'Une vibration accompagne les bips, les changements d\'intervalle et la fin de série.';

  @override
  String get paletteSection => 'COULEURS';

  @override
  String get seriesSection => 'SÉRIES ENREGISTRÉES';

  @override
  String get manageSeries => 'Gérer mes séries';

  @override
  String get manageSeriesHint => 'Lancer, renommer ou supprimer vos séries.';
}
