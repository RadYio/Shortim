import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// How far into the running interval the countdown is, used to decide which
/// face the mascot pulls. Kept distinct from any timing type: this is a pure
/// presentation state derived from [TimerSnapshot.progress].
enum MascotExpression { resting, fresh, mid, nearEnd, triumphant }

/// Picks the expression from the fraction of the current interval already
/// elapsed (`TimerSnapshot.progress`, in `[0, 1]`). A free function on
/// purpose, so the thresholds are unit-testable without pumping a widget.
/// Only ever returns one of the three "running" expressions — [resting] and
/// [triumphant] are driven by run status, see [mascotExpressionForState].
MascotExpression mascotExpressionForProgress(double progress) {
  if (progress < 0.4) return MascotExpression.fresh;
  if (progress < 0.75) return MascotExpression.mid;
  return MascotExpression.nearEnd;
}

/// Full expression, folding in run status: [finished] takes priority (the
/// series is over, win face), then [paused] (catching their breath), and
/// otherwise the usual progress-driven face from [mascotExpressionForProgress].
MascotExpression mascotExpressionForState({
  required bool paused,
  required bool finished,
  required double progress,
}) {
  if (finished) return MascotExpression.triumphant;
  if (paused) return MascotExpression.resting;
  return mascotExpressionForProgress(progress);
}

/// Continuous face parameters, all in 0..1 (`mouthCurve` in -1..1), so two
/// states can be cross-faded frame by frame — mirrors `MarkFrame` in
/// `shortim_mark.dart`.
typedef MascotFrame = ({
  double browFurrow,
  double mouthCurve,
  double mouthOpen,
  double tongue,
  double sweat,
});

/// Neutral, mildly smiling: the interval has just started.
const freshFrame = (
  browFurrow: 0.0,
  mouthCurve: 0.55,
  mouthOpen: 0.0,
  tongue: 0.0,
  sweat: 0.0,
);

/// Mid-effort: brows tighten, mouth flattens, a little sweat appears.
const midFrame = (
  browFurrow: 0.55,
  mouthCurve: 0.1,
  mouthOpen: 0.3,
  tongue: 0.0,
  sweat: 0.7,
);

/// Near the end: more intense, mouth wide open with the tongue out.
const nearEndFrame = (
  browFurrow: 0.9,
  mouthCurve: -0.15,
  mouthOpen: 0.9,
  tongue: 1.0,
  sweat: 1.0,
);

/// Paused: catching their breath — brows relaxed, a calmer half-smile, the
/// sweat from the effort so far still lingering a little.
const restingFrame = (
  browFurrow: -0.15,
  mouthCurve: 0.3,
  mouthOpen: 0.0,
  tongue: 0.0,
  sweat: 0.25,
);

/// Series finished: brows lifted, mouth wide open in a cheer, dried off.
const triumphantFrame = (
  browFurrow: -0.55,
  mouthCurve: 1.0,
  mouthOpen: 0.75,
  tongue: 0.0,
  sweat: 0.0,
);

/// The frame drawn for a given [MascotExpression].
MascotFrame frameFor(MascotExpression expression) => switch (expression) {
  MascotExpression.resting => restingFrame,
  MascotExpression.fresh => freshFrame,
  MascotExpression.mid => midFrame,
  MascotExpression.nearEnd => nearEndFrame,
  MascotExpression.triumphant => triumphantFrame,
};

/// Linear interpolation between two frames, field by field.
MascotFrame lerpMascotFrame(MascotFrame a, MascotFrame b, double t) => (
  browFurrow: lerpDouble(a.browFurrow, b.browFurrow, t)!,
  mouthCurve: lerpDouble(a.mouthCurve, b.mouthCurve, t)!,
  mouthOpen: lerpDouble(a.mouthOpen, b.mouthOpen, t)!,
  tongue: lerpDouble(a.tongue, b.tongue, t)!,
  sweat: lerpDouble(a.sweat, b.sweat, t)!,
);

/// A round-headed, stroke-only mascot wearing a sporty headband, styled
/// like `ShortimMarkPainter`: single colour, ~9px strokes, drawn on a
/// 100×100 grid. [frame] is a continuous blend of two [MascotExpression]s
/// so transitions can be animated smoothly by the caller.
class MascotPainter extends CustomPainter {
  const MascotPainter({required this.frame, required this.color});

  final MascotFrame frame;
  final Color color;

  static const _headCenter = Offset(50, 54);
  static const _headRadius = 32.0;
  static const _mouthY = 66.0;
  static const _mouthHalfWidth = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Head outline.
    canvas.drawCircle(_headCenter, _headRadius, stroke);

    // Sporty terry-cloth headband: a thick arc across the forehead.
    final bandRect = Rect.fromCircle(center: _headCenter, radius: _headRadius);
    canvas.drawArc(
      bandRect,
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      stroke..strokeWidth = 8,
    );
    stroke.strokeWidth = 6;

    // Eyebrows, furrowing inward as effort increases.
    final browLift = 6.0 * frame.browFurrow;
    canvas.drawLine(Offset(34, 42 + browLift), const Offset(44, 40), stroke);
    canvas.drawLine(Offset(66, 42 + browLift), const Offset(56, 40), stroke);

    // Eyes.
    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(const Offset(39, 52), 3, eyePaint);
    canvas.drawCircle(const Offset(61, 52), 3, eyePaint);

    _paintMouth(canvas, stroke);
    _paintSweat(canvas);
  }

  void _paintMouth(Canvas canvas, Paint stroke) {
    final mouthPaint = Paint.from(stroke)..strokeWidth = 5;
    if (frame.mouthOpen < 0.15) {
      // Closed mouth: a single curve, sagging into a smile ("u") or
      // flattening/inverting into a strained line ("n") as effort builds.
      final curveDy = 8 * frame.mouthCurve;
      final path = Path()
        ..moveTo(50 - _mouthHalfWidth, _mouthY)
        ..quadraticBezierTo(50, _mouthY + curveDy, 50 + _mouthHalfWidth, _mouthY);
      canvas.drawPath(path, mouthPaint);
      return;
    }

    // Open mouth: an oval outline, with the tongue poking out near the end.
    final openHeight = 6 + 10 * frame.mouthOpen;
    final mouthRect = Rect.fromCenter(
      center: Offset(50, _mouthY + openHeight / 4),
      width: _mouthHalfWidth * 2,
      height: openHeight,
    );
    canvas.drawOval(mouthRect, mouthPaint);
    if (frame.tongue > 0.01) {
      final tonguePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: frame.tongue.clamp(0.0, 1.0));
      final tongueRect = Rect.fromCenter(
        center: Offset(
          50,
          mouthRect.center.dy + openHeight * 0.2 * frame.tongue,
        ),
        width: _mouthHalfWidth * 1.1,
        height: openHeight * 0.65 * frame.tongue,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tongueRect, Radius.circular(tongueRect.width / 2)),
        tonguePaint,
      );
    }
  }

  void _paintSweat(Canvas canvas) {
    if (frame.sweat < 0.01) return;
    final sweatPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: (0.85 * frame.sweat).clamp(0.0, 1.0));
    void drop(Offset tip) {
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx - 4, tip.dy + 8, tip.dx, tip.dy + 12)
        ..quadraticBezierTo(tip.dx + 4, tip.dy + 8, tip.dx, tip.dy);
      canvas.drawPath(path, sweatPaint);
    }

    drop(const Offset(79, 38));
    if (frame.sweat > 0.5) drop(const Offset(85, 50));
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      frame != oldDelegate.frame || color != oldDelegate.color;
}
