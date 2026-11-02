import 'dart:async';

import 'package:audio_session/audio_session.dart' as ios;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_controller.dart';

/// Sounds played during a run. Abstracted so the run controller can be used
/// without a real audio backend.
abstract interface class SoundService {
  Future<void> init();

  /// Switches the cue set; applies from the next cue.
  Future<void> setTheme(SoundTheme theme);

  /// Countdown beep (T-3, T-2, T-1).
  Future<void> beep();

  /// A new interval starts.
  Future<void> intervalChange();

  /// The whole series is over.
  Future<void> finish();

  /// Keeps an audio session active (silent loop) so iOS does not suspend the
  /// app while it is in background or the screen is locked.
  Future<void> startKeepAlive();
  Future<void> stopKeepAlive();

  Future<void> dispose();
}

/// [SoundService] backed by `audioplayers`, using the WAV assets of the
/// current [SoundTheme] (`assets/sounds/<theme>/`).
///
/// The iOS audio session uses the `playback` category (required to play
/// with the screen locked, together with the `audio` background mode in
/// Info.plist) and `mixWithOthers`, so the user's music keeps playing.
///
/// **Ducking** (iOS): around each cue the session switches to
/// `mixWithOthers | duckOthers`, which lowers other apps' audio at the system
/// level, whatever the output (speaker, Bluetooth, AirPlay). Cues close to
/// each other (T-3, T-2, T-1, change) share one duck. [_duckHold] after the
/// last cue, the session is deactivated with `notifyOthersOnDeactivation`
/// (the only way iOS restores the others' volume, with its own soft ramp),
/// then reactivated without ducking. The silent keep-alive loop is paused for
/// those few milliseconds, since iOS refuses to deactivate a playing session.
/// Apps that ignore system ducking (rare) simply stay at full volume.
class AudioplayersSoundService implements SoundService {
  static const _duckHold = Duration(milliseconds: 700);

  final _beep = AudioPlayer(playerId: 'beep');
  final _change = AudioPlayer(playerId: 'change');
  final _finish = AudioPlayer(playerId: 'finish');
  final _silence = AudioPlayer(playerId: 'silence');

  /// Length of each loaded cue, to know when the duck can be released.
  final _cueLength = <AudioPlayer, Duration>{};

  SoundTheme _theme = SoundTheme.classic;
  bool _ready = false;
  bool _keepAlive = false;

  bool _ducked = false;
  Timer? _release;

  /// Session changes run one after the other, never interleaved.
  Future<void> _sessionOps = Future.value();

  bool get _canDuck => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      for (final player in [_beep, _change, _finish]) {
        await player.setReleaseMode(ReleaseMode.stop);
      }
      await _loadTheme();
      await _silence.setReleaseMode(ReleaseMode.loop);
      await _silence.setSource(AssetSource('sounds/silence.wav'));
      _ready = true;
    } catch (e, s) {
      // Audio failure must never break the timer itself.
      debugPrint('Sound init failed: $e\n$s');
    }
  }

  @override
  Future<void> setTheme(SoundTheme theme) async {
    if (theme == _theme) return;
    _theme = theme;
    if (!_ready) return; // init() loads the current theme.
    try {
      await _loadTheme();
    } catch (e) {
      debugPrint('Sound theme load failed: $e');
    }
  }

  Future<void> _loadTheme() async {
    for (final (player, cue) in [
      (_beep, 'beep'),
      (_change, 'change'),
      (_finish, 'finish'),
    ]) {
      await player.setSource(AssetSource('sounds/${_theme.name}/$cue.wav'));
      _cueLength[player] =
          await player.getDuration() ?? const Duration(seconds: 1);
    }
  }

  Future<void> _play(AudioPlayer player) async {
    if (!_ready) return;
    try {
      await _duck();
      // With ReleaseMode.stop the source stays loaded: rewind and replay.
      await player.stop();
      await player.resume();
      _scheduleRelease(_cueLength[player] ?? const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Sound playback failed: $e');
    }
  }

  @override
  Future<void> beep() => _play(_beep);

  @override
  Future<void> intervalChange() => _play(_change);

  @override
  Future<void> finish() => _play(_finish);

  Future<void> _serial(Future<void> Function() op) =>
      _sessionOps = _sessionOps.then((_) => op()).catchError((Object e) {
        debugPrint('Audio session change failed: $e');
      });

  /// Lowers other apps' audio until [_unduck]. Cheap when already ducked.
  Future<void> _duck() {
    _release?.cancel();
    if (!_canDuck) return Future.value();
    return _serial(() async {
      if (_ducked) return;
      final session = ios.AVAudioSession();
      await session.setCategory(
        ios.AVAudioSessionCategory.playback,
        ios.AVAudioSessionCategoryOptions.mixWithOthers |
            ios.AVAudioSessionCategoryOptions.duckOthers,
      );
      await session.setActive(true);
      _ducked = true;
    });
  }

  void _scheduleRelease(Duration cue) {
    if (!_canDuck) return;
    _release?.cancel();
    _release = Timer(cue + _duckHold, () => unawaited(_unduck()));
  }

  Future<void> _unduck() => _serial(() async {
    if (!_ducked) return;
    _ducked = false;
    final session = ios.AVAudioSession();
    try {
      if (_keepAlive) await _silence.pause();
      await session.setActive(
        false,
        avOptions:
            ios.AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
      await session.setCategory(
        ios.AVAudioSessionCategory.playback,
        ios.AVAudioSessionCategoryOptions.mixWithOthers,
      );
    } finally {
      if (_keepAlive) await _silence.resume();
    }
  });

  @override
  Future<void> startKeepAlive() async {
    if (!_ready) return;
    _keepAlive = true;
    try {
      await _silence.resume();
    } catch (e) {
      debugPrint('Keep-alive start failed: $e');
    }
  }

  @override
  Future<void> stopKeepAlive() async {
    if (!_ready) return;
    _keepAlive = false;
    try {
      await _silence.stop();
    } catch (e) {
      debugPrint('Keep-alive stop failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _release?.cancel();
    await _unduck();
    for (final p in [_beep, _change, _finish, _silence]) {
      await p.dispose();
    }
  }
}
