/// One step of a [Series]: a duration expressed as minutes + seconds.
///
/// Named `TimerInterval` rather than `Interval` to avoid clashing with
/// Flutter's `Interval` animation curve.
class TimerInterval {
  TimerInterval({required this.id, this.minutes = 0, this.seconds = 0})
    : assert(minutes >= 0 && minutes <= maxValue),
      assert(seconds >= 0 && seconds <= maxValue);

  static const int maxValue = 59;

  /// Stable identifier, used as a key when reordering the list.
  final String id;
  final int minutes;
  final int seconds;

  int get totalSeconds => minutes * 60 + seconds;

  Duration get duration => Duration(seconds: totalSeconds);

  bool get isValid => totalSeconds > 0;

  TimerInterval copyWith({String? id, int? minutes, int? seconds}) =>
      TimerInterval(
        id: id ?? this.id,
        minutes: minutes ?? this.minutes,
        seconds: seconds ?? this.seconds,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'minutes': minutes,
    'seconds': seconds,
  };

  factory TimerInterval.fromJson(Map<String, dynamic> json) => TimerInterval(
    id: json['id'] as String,
    minutes: (json['minutes'] as int).clamp(0, maxValue),
    seconds: (json['seconds'] as int).clamp(0, maxValue),
  );

  @override
  bool operator ==(Object other) =>
      other is TimerInterval &&
      other.id == id &&
      other.minutes == minutes &&
      other.seconds == seconds;

  @override
  int get hashCode => Object.hash(id, minutes, seconds);

  @override
  String toString() => 'TimerInterval($id, ${formatDuration(duration)})';
}

/// Formats a duration as `MM:SS`, or `H:MM:SS` once it reaches an hour.
String formatDuration(Duration d) {
  final total = d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
