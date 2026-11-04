import 'package:flutter/cupertino.dart';

import '../l10n/l10n.dart';
import '../theme.dart';

/// Two looping wheels (minutes, seconds), each 0-59.
///
/// Initial values are only read once: give the widget a new [Key] to show a
/// different interval.
class DurationPicker extends StatefulWidget {
  const DurationPicker({
    super.key,
    required this.minutes,
    required this.seconds,
    required this.onChanged,
    this.height = 150,
  });

  final int minutes;
  final int seconds;
  final void Function(int minutes, int seconds) onChanged;
  final double height;

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _minutes = widget.minutes;
  late int _seconds = widget.seconds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wheelSlot(
            _Wheel(
              initial: _minutes,
              label: context.l10n.minutesUnit,
              semanticsLabel: context.l10n.minutesLabel,
              onSelected: (v) {
                _minutes = v;
                widget.onChanged(_minutes, _seconds);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: TextStyle(fontSize: 30, color: AppColors.brand500),
            ),
          ),
          _wheelSlot(
            _Wheel(
              initial: _seconds,
              label: context.l10n.secondsUnit,
              semanticsLabel: context.l10n.secondsLabel,
              onSelected: (v) {
                _seconds = v;
                widget.onChanged(_minutes, _seconds);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Wheels share the available width, up to [_maxWheelWidth] each.
  static Widget _wheelSlot(Widget wheel) => Flexible(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWheelWidth),
      child: wheel,
    ),
  );

  static const _maxWheelWidth = 110.0;
}

class _Wheel extends StatefulWidget {
  const _Wheel({
    required this.initial,
    required this.label,
    required this.semanticsLabel,
    required this.onSelected,
  });

  final int initial;
  final String label;
  final String semanticsLabel;
  final ValueChanged<int> onSelected;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CupertinoPicker(
              scrollController: _controller,
              itemExtent: 48,
              looping: true,
              magnification: 1.1,
              useMagnifier: true,
              selectionOverlay: const _SelectionOverlay(),
              onSelectedItemChanged: (i) => widget.onSelected(i % 60),
              children: [
                for (var i = 0; i < 60; i++)
                  Center(
                    child: Text(
                      i.toString().padLeft(2, '0'),
                      style: AppText.mono(fontSize: 32),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: 4,
              child: IgnorePointer(
                child: Text(
                  widget.label,
                  style: AppText.mono(fontSize: 12, color: AppColors.brand500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.brand700),
        ),
      ),
    );
  }
}
