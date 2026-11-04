import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'l10n/l10n.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/settings_controller.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  configureFonts();
  final storage = StorageService();
  // Loaded before the first frame: no flash of the wrong language/accent.
  final settings = SettingsController(storage);
  await settings.load();
  runApp(
    ShortimApp(
      sounds: AudioplayersSoundService(),
      storage: storage,
      settings: settings,
    ),
  );
}

class ShortimApp extends StatefulWidget {
  const ShortimApp({
    super.key,
    required this.sounds,
    required this.storage,
    this.settings,
  });

  final SoundService sounds;
  final StorageService storage;

  /// Already loaded settings; when null they are loaded on startup.
  final SettingsController? settings;

  @override
  State<ShortimApp> createState() => _ShortimAppState();
}

class _ShortimAppState extends State<ShortimApp> {
  late final SettingsController _settings =
      widget.settings ?? (SettingsController(widget.storage)..load());

  @override
  void initState() {
    super.initState();
    _settings.addListener(_applySoundTheme);
    _applySoundTheme();
  }

  @override
  void dispose() {
    _settings.removeListener(_applySoundTheme);
    super.dispose();
  }

  void _applySoundTheme() =>
      unawaited(widget.sounds.setTheme(_settings.settings.soundTheme));

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      notifier: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          final settings = _settings.settings;
          return MaterialApp(
            title: 'Shortim',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(palette: settings.palette),
            themeAnimationDuration: AppMotion.slow,
            themeAnimationCurve: AppMotion.brand,
            locale: settings.language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeListResolutionCallback: (device, _) =>
                resolveDeviceLocale(device),
            home: SplashScreen(
              next: (_) =>
                  _AfterSplash(sounds: widget.sounds, storage: widget.storage),
            ),
          );
        },
      ),
    );
  }
}

/// Decides between the first-run onboarding and the main shell, based on
/// the persisted flag — never re-shown once onboarding has completed.
class _AfterSplash extends StatefulWidget {
  const _AfterSplash({required this.sounds, required this.storage});

  final SoundService sounds;
  final StorageService storage;

  @override
  State<_AfterSplash> createState() => _AfterSplashState();
}

class _AfterSplashState extends State<_AfterSplash> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    widget.storage.hasOnboarded().then((v) {
      if (mounted) setState(() => _onboarded = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) return const SizedBox.shrink();
    if (_onboarded == false) {
      return OnboardingScreen(
        sounds: widget.sounds,
        storage: widget.storage,
        onDone: () => setState(() => _onboarded = true),
      );
    }
    return AppShell(sounds: widget.sounds, storage: widget.storage);
  }
}

/// Fonts ship in `assets/google_fonts/`: never fetch them at runtime.
void configureFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final font in ['PlayfairDisplay', 'JetBrainsMono']) {
      final text = await rootBundle.loadString(
        'assets/google_fonts/OFL-$font.txt',
      );
      yield LicenseEntryWithLineBreaks(['google_fonts'], text);
    }
  });
}
