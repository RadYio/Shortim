import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/setup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  configureFonts();
  runApp(
    ShortimApp(sounds: AudioplayersSoundService(), storage: StorageService()),
  );
}

class ShortimApp extends StatelessWidget {
  const ShortimApp({super.key, required this.sounds, required this.storage});

  final SoundService sounds;
  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shortim',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: SplashScreen(
        next: (_) => SetupScreen(sounds: sounds, storage: storage),
      ),
    );
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
