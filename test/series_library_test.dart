import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/models/saved_series.dart';
import 'package:shortim/models/series.dart';
import 'package:shortim/models/timer_interval.dart';
import 'package:shortim/services/series_library.dart';
import 'package:shortim/services/storage_service.dart';

Series _series(int seconds, {int repeat = 1}) => Series(
  intervals: [TimerInterval(id: 'a', seconds: seconds)],
  loopMode: repeat > 1 ? LoopMode.repeatN : LoopMode.once,
  loopCount: repeat,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves, persists and reloads', () async {
    final library = SeriesLibrary(StorageService());
    await library.save('Muscu1', _series(30, repeat: 3));
    await library.save('Course', _series(45));

    final reloaded = SeriesLibrary(StorageService());
    await reloaded.load();
    expect(reloaded.items.map((s) => s.name), ['Course', 'Muscu1']);
    expect(reloaded.items.last.series.rounds, 3);
  });

  test('saving an existing name replaces it in place', () async {
    final library = SeriesLibrary(StorageService());
    final first = await library.save('Muscu1', _series(30));
    await library.save('Course', _series(45));
    final replaced = await library.save(' muscu1 ', _series(20));

    expect(replaced.id, first.id);
    expect(library.items.map((s) => s.name), ['Course', 'muscu1']);
    expect(library.items.last.series.roundDuration.inSeconds, 20);
  });

  test('rename refuses a name used by another series', () async {
    final library = SeriesLibrary(StorageService());
    final a = await library.save('A', _series(10));
    await library.save('B', _series(10));

    expect(await library.rename(a.id, 'b'), isFalse);
    expect(await library.rename(a.id, 'a'), isTrue); // Own name: allowed.
    expect(await library.rename(a.id, 'C'), isTrue);
    expect(library.byName('c')?.id, a.id);
  });

  test('delete then restore puts the series back in place', () async {
    final library = SeriesLibrary(StorageService());
    await library.save('A', _series(10));
    final b = await library.save('B', _series(10));
    await library.save('C', _series(10));

    final index = await library.delete(b.id);
    expect(library.items.map((s) => s.name), ['C', 'A']);
    await library.restore(b, index);
    expect(library.items.map((s) => s.name), ['C', 'B', 'A']);
  });

  test('a corrupted entry is skipped, not the whole library', () async {
    SharedPreferences.setMockInitialValues({
      'saved_series':
          '[{"id":"1","name":"Ok","intervals":[{"id":"a","minutes":0,'
          '"seconds":5}],"loopMode":"once","loopCount":1},{"broken":true}]',
    });
    final library = SeriesLibrary(StorageService());
    await library.load();
    expect(library.items.single.name, 'Ok');
  });

  test('summary reads "N intervalles · MM:SS · ×R"', () {
    final saved = SavedSeries(
      id: '1',
      name: 'X',
      series: Series(
        intervals: [
          TimerInterval(id: 'a', minutes: 1),
          TimerInterval(id: 'b', seconds: 30),
        ],
        loopMode: LoopMode.repeatN,
        loopCount: 3,
      ),
    );
    expect(saved.summary, '2 intervalles · 01:30 · ×3');
  });
}
