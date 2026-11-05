import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart' show Colors;
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

/// A shaded, rooster-shaped "sports coach" mascot — gradients and a soft
/// ground shadow give it volume (a 3D *look*, rendered flat: this stays a
/// `CustomPainter`, no mesh/asset, so [frame] can keep morphing it live
/// frame by frame exactly like the previous flat version did) on a 100×100
/// grid. The comb/beak/wattle/feathers use a fixed warm palette so the bird
/// stays recognisable in every app palette; only the headband — the one
/// "branded" item it wears — follows [accentColor] (the current palette's
/// accent2), so it always matches the rest of the UI.
class MascotPainter extends CustomPainter {
  const MascotPainter({required this.frame, required this.accentColor});

  final MascotFrame frame;
  final Color accentColor;

  static const _headCenter = Offset(50, 58);
  static const _headRadius = 27.0;
  static const _beakY = 64.0;

  // Fixed "rooster" palette — independent of the app's theme, so the bird
  // itself always reads the same way; only the headband is themed.
  static const _featherLight = Color(0xFFFBE2A7);
  static const _featherDark = Color(0xFFD99A45);
  static const _combLight = Color(0xFFFF7A59);
  static const _combDark = Color(0xFFD03A1F);
  static const _beakLight = Color(0xFFFFCE63);
  static const _beakDark = Color(0xFFE28A1E);
  static const _ink = Color(0xFF3B2A1C);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    _paintGroundShadow(canvas);
    _paintComb(canvas);
    _paintWattle(canvas);
    _paintHead(canvas);
    _paintHeadband(canvas);
    _paintEyebrows(canvas);
    _paintEyes(canvas);
    _paintBeak(canvas);
    _paintSweat(canvas);
  }

  void _paintGroundShadow(Canvas canvas) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 92), width: 34, height: 7),
      shadow,
    );
  }

  /// Three overlapping lobes, each with its own radial gradient so the comb
  /// doesn't read as one flat red shape.
  void _paintComb(Canvas canvas) {
    const centers = [Offset(38, 30), Offset(50, 22), Offset(62, 30)];
    const radii = [8.0, 9.5, 8.0];
    for (var i = 0; i < centers.length; i++) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          centers[i] - const Offset(2, 2),
          radii[i] * 1.4,
          [_combLight, _combDark],
        );
      canvas.drawCircle(centers[i], radii[i], paint);
    }
  }

  /// A small dangling lobe under the beak, same red family as the comb.
  void _paintWattle(Canvas canvas) {
    final center = Offset(50, _beakY + 10 + 3 * frame.sweat);
    final paint = Paint()
      ..shader = ui.Gradient.radial(center - const Offset(1, 1), 7, [
        _combLight,
        _combDark,
      ]);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 9, height: 12),
      paint,
    );
  }

  /// The head itself: a radial gradient (lit from the upper-left) gives it
  /// volume, plus a soft darker arc along the lower edge for extra depth.
  void _paintHead(Canvas canvas) {
    final body = Paint()
      ..shader = ui.Gradient.radial(
        _headCenter - const Offset(10, 10),
        _headRadius * 1.9,
        [_featherLight, _featherDark],
      );
    canvas.drawCircle(_headCenter, _headRadius, body);

    final occlusion = Paint()
      ..shader = ui.Gradient.radial(
        _headCenter + const Offset(6, 10),
        _headRadius * 1.1,
        [_featherDark.withValues(alpha: 0.55), _featherDark.withValues(alpha: 0)],
      );
    canvas.drawCircle(_headCenter, _headRadius, occlusion);

    // A small highlight catching the light, for shine.
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(_headCenter + const Offset(-12, -14), 5, shine);
  }

  /// A terry-cloth headband wrapping the forehead, following the curve of
  /// the head (varying width + a highlight stripe) so it reads as cloth
  /// wrapped around a round volume rather than a flat ring. The one themed
  /// part of the mascot: [accentColor] is the current palette's accent2.
  void _paintHeadband(Canvas canvas) {
    final bandRect = Rect.fromCircle(
      center: _headCenter,
      radius: _headRadius + 1,
    );
    const start = math.pi * 1.1;
    const sweep = math.pi * 0.8;
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 11
      ..shader = ui.Gradient.linear(
        Offset(_headCenter.dx - _headRadius, _headCenter.dy - _headRadius),
        Offset(_headCenter.dx + _headRadius, _headCenter.dy),
        [
          Color.lerp(accentColor, Colors.black, 0.25)!,
          accentColor,
          Color.lerp(accentColor, Colors.black, 0.25)!,
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawArc(bandRect, start, sweep, false, band);

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawArc(
      bandRect.deflate(1.5),
      start + 0.12,
      sweep - 0.3,
      false,
      highlight,
    );

    // Little knotted tail flaring off to the side, for a sporty finish.
    final knotPaint = Paint()..color = Color.lerp(accentColor, Colors.black, 0.15)!;
    final knotCenter = Offset(
      _headCenter.dx + (_headRadius + 1) * math.cos(start + sweep),
      _headCenter.dy + (_headRadius + 1) * math.sin(start + sweep),
    );
    canvas.save();
    canvas.translate(knotCenter.dx, knotCenter.dy);
    canvas.rotate(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2, 0, 4, 9),
        const Radius.circular(2),
      ),
      knotPaint,
    );
    canvas.restore();
  }

  /// Furrowing inward (brows down, effort) or lifting (brows up, happy).
  void _paintEyebrows(Canvas canvas) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    final browLift = 4.5 * frame.browFurrow;
    canvas.drawLine(Offset(35, 45 + browLift), const Offset(42, 43), stroke);
    canvas.drawLine(Offset(65, 45 + browLift), const Offset(58, 43), stroke);
  }

  /// White sclera + dark pupil with a tiny catchlight, for a glossy,
  /// dimensional look instead of flat dots.
  void _paintEyes(Canvas canvas) {
    for (final cx in [39.0, 61.0]) {
      final center = Offset(cx, 55);
      canvas.drawCircle(center, 4.6, Paint()..color = Colors.white);
      canvas.drawCircle(center, 3.0, Paint()..color = _ink);
      canvas.drawCircle(
        center + const Offset(-1, -1),
        1.1,
        Paint()..color = Colors.white,
      );
    }
  }

  /// A two-part beak: the upper mandible is fixed, the lower one drops open
  /// with [MascotFrame.mouthOpen] and the tongue pokes out past it.
  void _paintBeak(Canvas canvas) {
    const halfWidth = 7.0;
    final curveDy = 2.5 * frame.mouthCurve;
    final openGap = 10 * frame.mouthOpen;

    final upper = Path()
      ..moveTo(50 - halfWidth, _beakY)
      ..lineTo(50, _beakY - 4 - curveDy)
      ..lineTo(50 + halfWidth, _beakY)
      ..close();
    canvas.drawPath(
      upper,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(50, _beakY - 6),
          Offset(50, _beakY),
          [_beakLight, _beakDark],
        ),
    );

    final lower = Path()
      ..moveTo(50 - halfWidth * 0.85, _beakY + openGap)
      ..lineTo(50, _beakY + 5 + openGap - curveDy)
      ..lineTo(50 + halfWidth * 0.85, _beakY + openGap)
      ..close();
    canvas.drawPath(
      lower,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(50, _beakY + openGap),
          Offset(50, _beakY + 5 + openGap),
          [_beakDark, _beakLight],
        ),
    );

    if (frame.tongue > 0.01 && frame.mouthOpen > 0.15) {
      final tonguePaint = Paint()
        ..color = _combLight.withValues(alpha: frame.tongue.clamp(0.0, 1.0));
      final tongueRect = Rect.fromCenter(
        center: Offset(50, _beakY + openGap + 2),
        width: halfWidth * 0.9,
        height: 3 + 4 * frame.tongue,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tongueRect, const Radius.circular(2)),
        tonguePaint,
      );
    }
  }

  void _paintSweat(Canvas canvas) {
    if (frame.sweat < 0.01) return;
    final sweatPaint = Paint()
      ..color = const Color(0xFF9BD4FF).withValues(
        alpha: (0.85 * frame.sweat).clamp(0.0, 1.0),
      );
    void drop(Offset tip) {
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx - 3.5, tip.dy + 7, tip.dx, tip.dy + 10)
        ..quadraticBezierTo(tip.dx + 3.5, tip.dy + 7, tip.dx, tip.dy);
      canvas.drawPath(path, sweatPaint);
    }

    drop(const Offset(76, 40));
    if (frame.sweat > 0.5) drop(const Offset(81, 52));
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      frame != oldDelegate.frame || accentColor != oldDelegate.accentColor;
}
