import 'series.dart';
import 'timer_interval.dart';

/// A series the user named and kept in "Mes séries".
class SavedSeries {
  const SavedSeries({
    required this.id,
    required this.name,
    required this.series,
  });

  static const int maxNameLength = 40;

  final String id;
  final String name;
  final Series series;

  SavedSeries copyWith({String? name, Series? series}) => SavedSeries(
    id: id,
    name: name ?? this.name,
    series: series ?? this.series,
  );

  /// One-line summary, e.g. "8 intervalles · 12:30 · ×3". The duration is
  /// one pass through the intervals; "×N" is shown when it repeats.
  String get summary {
    final count = series.intervals.length;
    return [
      '$count ${count > 1 ? 'intervalles' : 'intervalle'}',
      formatDuration(series.roundDuration),
      if (series.rounds > 1) '×${series.rounds}',
    ].join(' · ');
  }

  /// `{id, name, intervals, loopMode, loopCount}`.
  Map<String, Object> toJson() => {'id': id, 'name': name, ...series.toJson()};

  factory SavedSeries.fromJson(Map<String, dynamic> json) => SavedSeries(
    id: json['id'] as String,
    name: json['name'] as String,
    series: Series.fromJson(json),
  );
}
