import 'timer_interval.dart';

enum LoopMode { once, repeatN }

/// An ordered list of intervals, played once or repeated N times.
class Series {
  Series({
    required List<TimerInterval> intervals,
    this.loopMode = LoopMode.once,
    this.loopCount = 1,
  }) : intervals = List.unmodifiable(intervals),
       assert(intervals.length <= maxIntervals),
       assert(loopCount >= 1);

  static const int maxIntervals = 30;
  static const int maxLoopCount = 99;

  final List<TimerInterval> intervals;
  final LoopMode loopMode;

  /// Only meaningful when [loopMode] is [LoopMode.repeatN].
  final int loopCount;

  /// Number of passes through the whole interval list.
  int get rounds => loopMode == LoopMode.repeatN ? loopCount : 1;

  /// A series can be started when it has at least one interval and every
  /// interval has a strictly positive duration.
  bool get isValid =>
      intervals.isNotEmpty &&
      intervals.length <= maxIntervals &&
      intervals.every((i) => i.isValid);

  /// Duration of a single pass through the intervals.
  Duration get roundDuration =>
      intervals.fold(Duration.zero, (sum, i) => sum + i.duration);

  /// Duration of the whole run, all rounds included.
  Duration get totalDuration => roundDuration * rounds;

  Map<String, Object> toJson() => {
    'intervals': [for (final i in intervals) i.toJson()],
    'loopMode': loopMode.name,
    'loopCount': loopCount,
  };

  factory Series.fromJson(Map<String, dynamic> json) => Series(
    intervals: [
      for (final i in (json['intervals'] as List).take(maxIntervals))
        TimerInterval.fromJson(i as Map<String, dynamic>),
    ],
    loopMode: LoopMode.values.firstWhere(
      (m) => m.name == json['loopMode'],
      orElse: () => LoopMode.once,
    ),
    loopCount: (json['loopCount'] as int? ?? 1).clamp(1, maxLoopCount),
  );
}
