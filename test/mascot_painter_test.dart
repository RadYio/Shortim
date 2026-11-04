import 'package:flutter_test/flutter_test.dart';
import 'package:shortim/widgets/mascot_painter.dart';

void main() {
  group('mascotExpressionForProgress', () {
    test('fresh below 0.4', () {
      expect(mascotExpressionForProgress(0), MascotExpression.fresh);
      expect(mascotExpressionForProgress(0.2), MascotExpression.fresh);
      expect(mascotExpressionForProgress(0.39), MascotExpression.fresh);
    });

    test('mid between 0.4 and 0.75', () {
      expect(mascotExpressionForProgress(0.4), MascotExpression.mid);
      expect(mascotExpressionForProgress(0.6), MascotExpression.mid);
      expect(mascotExpressionForProgress(0.74), MascotExpression.mid);
    });

    test('nearEnd from 0.75 up to 1', () {
      expect(mascotExpressionForProgress(0.75), MascotExpression.nearEnd);
      expect(mascotExpressionForProgress(0.9), MascotExpression.nearEnd);
      expect(mascotExpressionForProgress(1), MascotExpression.nearEnd);
    });
  });

  group('mascotExpressionForState', () {
    test('finished wins over everything else', () {
      expect(
        mascotExpressionForState(paused: true, finished: true, progress: 0),
        MascotExpression.triumphant,
      );
    });

    test('paused shows the resting face while running progress is ignored', () {
      expect(
        mascotExpressionForState(paused: true, finished: false, progress: 0.9),
        MascotExpression.resting,
      );
    });

    test('otherwise falls back to the progress-driven face', () {
      expect(
        mascotExpressionForState(paused: false, finished: false, progress: 0.1),
        MascotExpression.fresh,
      );
    });
  });

  group('lerpMascotFrame', () {
    test('t = 0 returns the first frame, t = 1 the second', () {
      expect(lerpMascotFrame(freshFrame, nearEndFrame, 0), freshFrame);
      expect(lerpMascotFrame(freshFrame, nearEndFrame, 1), nearEndFrame);
    });

    test('t = 0.5 is the midpoint of each field', () {
      final mid = lerpMascotFrame(freshFrame, nearEndFrame, 0.5);
      expect(mid.sweat, (freshFrame.sweat + nearEndFrame.sweat) / 2);
      expect(mid.tongue, (freshFrame.tongue + nearEndFrame.tongue) / 2);
    });
  });
}
