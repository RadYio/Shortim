import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sounds played during a run. Abstracted so the run controller can be used
/// without a real audio backend.
abstract interface class SoundService {
  Future<void> init();

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

/// [SoundService] backed by `audioplayers`, using bundled WAV assets.
///
/// The iOS audio session uses the `playback` category (required to play
/// with the screen locked, together with the `audio` background mode in
/// Info.plist) and `mixWithOthers`, so the user's music keeps playing.
class AudioplayersSoundService implements SoundService {
  final _beep = AudioPlayer(playerId: 'beep');
  final _change = AudioPlayer(playerId: 'change');
  final _finish = AudioPlayer(playerId: 'finish');
  final _silence = AudioPlayer(playerId: 'silence');

  bool _ready = false;

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
      for (final (player, asset) in [
        (_beep, 'sounds/beep.wav'),
        (_change, 'sounds/interval_change.wav'),
        (_finish, 'sounds/finish.wav'),
      ]) {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(asset));
      }
      await _silence.setReleaseMode(ReleaseMode.loop);
      await _silence.setSource(AssetSource('sounds/silence.wav'));
      _ready = true;
    } catch (e, s) {
      // Audio failure must never break the timer itself.
      debugPrint('Sound init failed: $e\n$s');
    }
  }

  Future<void> _play(AudioPlayer player) async {
    if (!_ready) return;
    try {
      // With ReleaseMode.stop the source stays loaded: rewind and replay.
      await player.stop();
      await player.resume();
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

  @override
  Future<void> startKeepAlive() async {
    if (!_ready) return;
    try {
      await _silence.resume();
    } catch (e) {
      debugPrint('Keep-alive start failed: $e');
    }
  }

  @override
  Future<void> stopKeepAlive() async {
    if (!_ready) return;
    try {
      await _silence.stop();
    } catch (e) {
      debugPrint('Keep-alive stop failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    for (final p in [_beep, _change, _finish, _silence]) {
      await p.dispose();
    }
  }
}
