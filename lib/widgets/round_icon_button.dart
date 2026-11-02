import 'package:flutter/material.dart';

import '../theme.dart';

/// Circular accent-outlined icon button. When [enabled] is false it is drawn
/// dimmed but stays tappable, so callers can explain why it is unavailable.
/// Shrinks slightly while pressed and springs back on release.
class RoundIconButton extends StatefulWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.enabled = true,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool enabled;
  final double size;

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final RoundIconButton(:icon, :onPressed, :tooltip, :enabled, :size) =
        widget;
    final color = enabled
        ? Theme.of(context).colorScheme.primary
        : AppColors.brand700;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          radius: size / 2 + 4,
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1,
            duration: _pressed ? AppMotion.fast : AppMotion.slow,
            curve: _pressed ? AppMotion.brand : AppMotion.emphasis,
            child: AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.brand,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(icon, color: color, size: size * 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
