import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Eyebrow above the duration picker.
  ///
  /// In fr, this message translates to:
  /// **'INTERVALLE {number}'**
  String intervalLabel(int number);

  /// No description provided for @addInterval.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un intervalle'**
  String get addInterval;

  /// No description provided for @removeInterval.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get removeInterval;

  /// No description provided for @moveInterval.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get moveInterval;

  /// No description provided for @mySeries.
  ///
  /// In fr, this message translates to:
  /// **'Mes séries'**
  String get mySeries;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @chronoTab.
  ///
  /// In fr, this message translates to:
  /// **'Chrono'**
  String get chronoTab;

  /// No description provided for @onboardWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Shortim'**
  String get onboardWelcomeTitle;

  /// No description provided for @onboardWelcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Crée une série de minuteurs sur-mesure et lance-la en quelques secondes.'**
  String get onboardWelcomeSubtitle;

  /// No description provided for @onboardStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardStart;

  /// No description provided for @onboardCategoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel type de séance ?'**
  String get onboardCategoryTitle;

  /// No description provided for @onboardCategorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'On te prépare une première série adaptée.'**
  String get onboardCategorySubtitle;

  /// No description provided for @onboardHiit.
  ///
  /// In fr, this message translates to:
  /// **'HIIT'**
  String get onboardHiit;

  /// No description provided for @onboardHiitHint.
  ///
  /// In fr, this message translates to:
  /// **'8 tours · 20 s effort / 10 s repos'**
  String get onboardHiitHint;

  /// No description provided for @onboardStretch.
  ///
  /// In fr, this message translates to:
  /// **'Étirements'**
  String get onboardStretch;

  /// No description provided for @onboardStretchHint.
  ///
  /// In fr, this message translates to:
  /// **'6 positions · 30 s chacune'**
  String get onboardStretchHint;

  /// No description provided for @onboardBreathing.
  ///
  /// In fr, this message translates to:
  /// **'Respiration'**
  String get onboardBreathing;

  /// No description provided for @onboardBreathingHint.
  ///
  /// In fr, this message translates to:
  /// **'5 cycles · inspire / retiens / expire'**
  String get onboardBreathingHint;

  /// No description provided for @onboardCustom.
  ///
  /// In fr, this message translates to:
  /// **'Perso'**
  String get onboardCustom;

  /// No description provided for @onboardCustomHint.
  ///
  /// In fr, this message translates to:
  /// **'Un minuteur simple, à régler toi-même'**
  String get onboardCustomHint;

  /// No description provided for @onboardResultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ta première série est prête'**
  String get onboardResultTitle;

  /// No description provided for @onboardStartNow.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer maintenant'**
  String get onboardStartNow;

  /// No description provided for @onboardEditFirst.
  ///
  /// In fr, this message translates to:
  /// **'Modifier d\'abord'**
  String get onboardEditFirst;

  /// No description provided for @maxIntervals.
  ///
  /// In fr, this message translates to:
  /// **'{max} intervalles maximum'**
  String maxIntervals(int max);

  /// No description provided for @totalDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée totale : {duration}'**
  String totalDuration(String duration);

  /// No description provided for @totalDurationRounds.
  ///
  /// In fr, this message translates to:
  /// **'Durée totale : {total}  ({rounds} × {round})'**
  String totalDurationRounds(String total, int rounds, String round);

  /// No description provided for @emptyIntervalWarning.
  ///
  /// In fr, this message translates to:
  /// **'Chaque intervalle doit durer au moins 1 seconde'**
  String get emptyIntervalWarning;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get start;

  /// No description provided for @loopOnce.
  ///
  /// In fr, this message translates to:
  /// **'1 fois'**
  String get loopOnce;

  /// No description provided for @loopRepeat.
  ///
  /// In fr, this message translates to:
  /// **'Répéter x fois'**
  String get loopRepeat;

  /// No description provided for @loopCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fois} other{{count} fois}}'**
  String loopCount(int count);

  /// No description provided for @fewerRepeats.
  ///
  /// In fr, this message translates to:
  /// **'Moins de répétitions'**
  String get fewerRepeats;

  /// No description provided for @moreRepeats.
  ///
  /// In fr, this message translates to:
  /// **'Plus de répétitions'**
  String get moreRepeats;

  /// No description provided for @interruptedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Série interrompue'**
  String get interruptedTitle;

  /// No description provided for @interruptedBody.
  ///
  /// In fr, this message translates to:
  /// **'Une série était en cours. La reprendre ?'**
  String get interruptedBody;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @resume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resume;

  /// No description provided for @savedSnack.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » enregistrée'**
  String savedSnack(String name);

  /// No description provided for @updatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » mise à jour'**
  String updatedSnack(String name);

  /// No description provided for @minutesUnit.
  ///
  /// In fr, this message translates to:
  /// **'min'**
  String get minutesUnit;

  /// No description provided for @secondsUnit.
  ///
  /// In fr, this message translates to:
  /// **'s'**
  String get secondsUnit;

  /// No description provided for @minutesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @secondsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Secondes'**
  String get secondsLabel;

  /// No description provided for @runInterval.
  ///
  /// In fr, this message translates to:
  /// **'INTERVALLE {index}/{count}'**
  String runInterval(int index, int count);

  /// No description provided for @runRound.
  ///
  /// In fr, this message translates to:
  /// **'TOUR {round}/{rounds}'**
  String runRound(int round, int rounds);

  /// No description provided for @paused.
  ///
  /// In fr, this message translates to:
  /// **'EN PAUSE'**
  String get paused;

  /// No description provided for @nextInterval.
  ///
  /// In fr, this message translates to:
  /// **'Suivant : {duration}'**
  String nextInterval(String duration);

  /// No description provided for @lastInterval.
  ///
  /// In fr, this message translates to:
  /// **'Dernier intervalle'**
  String get lastInterval;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get stop;

  /// No description provided for @restart.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get restart;

  /// No description provided for @newSeries.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle série'**
  String get newSeries;

  /// No description provided for @stopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la série ?'**
  String get stopTitle;

  /// No description provided for @continueRun.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueRun;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @seriesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 SÉRIE} other{{count} SÉRIES}}'**
  String seriesCount(int count);

  /// No description provided for @launch.
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get launch;

  /// No description provided for @options.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @rename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deletedSnack.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » supprimée'**
  String deletedSnack(String name);

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série enregistrée'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryHint.
  ///
  /// In fr, this message translates to:
  /// **'Composez une série puis touchez « Enregistrer ».'**
  String get emptyLibraryHint;

  /// No description provided for @intervalCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 intervalle} other{{count} intervalles}}'**
  String intervalCount(int count);

  /// No description provided for @saveSeriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la série'**
  String get saveSeriesTitle;

  /// No description provided for @nameHint.
  ///
  /// In fr, this message translates to:
  /// **'Muscu1'**
  String get nameHint;

  /// No description provided for @replace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get replace;

  /// No description provided for @replaceHelper.
  ///
  /// In fr, this message translates to:
  /// **'Une série porte déjà ce nom : elle sera remplacée.'**
  String get replaceHelper;

  /// No description provided for @nameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom est déjà utilisé.'**
  String get nameTaken;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @languageSection.
  ///
  /// In fr, this message translates to:
  /// **'LANGUE'**
  String get languageSection;

  /// No description provided for @languageAuto.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// No description provided for @languageAutoHint.
  ///
  /// In fr, this message translates to:
  /// **'Auto suit la langue de l\'appareil (actuellement : {language}).'**
  String languageAutoHint(String language);

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @soundSection.
  ///
  /// In fr, this message translates to:
  /// **'SON'**
  String get soundSection;

  /// No description provided for @soundToggle.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get soundToggle;

  /// No description provided for @soundToggleHint.
  ///
  /// In fr, this message translates to:
  /// **'Bips du compte à rebours, changement d\'intervalle et fin de série.'**
  String get soundToggleHint;

  /// No description provided for @duckingHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre musique baisse le temps de chaque son, puis remonte doucement (y compris en Bluetooth et AirPlay).'**
  String get duckingHint;

  /// No description provided for @soundThemeClassic.
  ///
  /// In fr, this message translates to:
  /// **'Bip classique'**
  String get soundThemeClassic;

  /// No description provided for @soundThemeBell.
  ///
  /// In fr, this message translates to:
  /// **'Cloche douce'**
  String get soundThemeBell;

  /// No description provided for @soundThemeMarimba.
  ///
  /// In fr, this message translates to:
  /// **'Marimba'**
  String get soundThemeMarimba;

  /// No description provided for @soundThemePulse.
  ///
  /// In fr, this message translates to:
  /// **'Pulse électro'**
  String get soundThemePulse;

  /// No description provided for @previewSoundFor.
  ///
  /// In fr, this message translates to:
  /// **'Écouter : {name}'**
  String previewSoundFor(String name);

  /// No description provided for @hapticsSection.
  ///
  /// In fr, this message translates to:
  /// **'VIBRATIONS'**
  String get hapticsSection;

  /// No description provided for @hapticsToggle.
  ///
  /// In fr, this message translates to:
  /// **'Vibrations'**
  String get hapticsToggle;

  /// No description provided for @hapticsHint.
  ///
  /// In fr, this message translates to:
  /// **'Une vibration accompagne les bips, les changements d\'intervalle et la fin de série.'**
  String get hapticsHint;

  /// No description provided for @paletteSection.
  ///
  /// In fr, this message translates to:
  /// **'COULEURS'**
  String get paletteSection;

  /// No description provided for @seriesSection.
  ///
  /// In fr, this message translates to:
  /// **'SÉRIES ENREGISTRÉES'**
  String get seriesSection;

  /// No description provided for @manageSeries.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes séries'**
  String get manageSeries;

  /// No description provided for @manageSeriesHint.
  ///
  /// In fr, this message translates to:
  /// **'Lancer, renommer ou supprimer vos séries.'**
  String get manageSeriesHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
