import 'series.dart';

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

  /// `{id, name, intervals, loopMode, loopCount}`.
  Map<String, Object> toJson() => {'id': id, 'name': name, ...series.toJson()};

  factory SavedSeries.fromJson(Map<String, dynamic> json) => SavedSeries(
    id: json['id'] as String,
    name: json['name'] as String,
    series: Series.fromJson(json),
  );
}
