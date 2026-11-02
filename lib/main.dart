import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/setup_screen.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
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
      home: SetupScreen(sounds: sounds, storage: storage),
    );
  }
}
