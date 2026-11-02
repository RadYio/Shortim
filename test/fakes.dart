import 'package:shortim/services/sound_service.dart';

class FakeSoundService implements SoundService {
  final played = <String>[];

  @override
  Future<void> init() async {}
  @override
  Future<void> beep() async => played.add('beep');
  @override
  Future<void> intervalChange() async => played.add('change');
  @override
  Future<void> finish() async => played.add('finish');
  @override
  Future<void> startKeepAlive() async {}
  @override
  Future<void> stopKeepAlive() async {}
  @override
  Future<void> dispose() async {}
}
