import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// The three destinations always reachable from the bottom menu.
enum AppSection { chrono, settings, library }

/// One destination in a [FloatingMenuBar].
class MenuBarItem {
  const MenuBarItem({
    required this.section,
    required this.icon,
    required this.label,
  });

  final AppSection section;
  final IconData icon;
  final String label;
}

/// Quiet, secondary floating pill, persistent across every screen (shown
/// by [AppShell]). Frosted/translucent rather than solid — it stays out of
/// the way of Chrono, the main frame — with a soft glow (not a hard block)
/// fading in behind whichever destination is current.
class FloatingMenuBar extends StatelessWidget {
  const FloatingMenuBar({
    super.key,
    required this.current,
    required this.onSelect,
    required this.items,
  });

  final AppSection current;
  final ValueChanged<AppSection> onSelect;
  final List<MenuBarItem> items;

  @override
  Widget build(BuildContext context) {
    final index = items.indexWhere((i) => i.section == current);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.brand700.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = constraints.maxWidth / items.length;
                return SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: AppMotion.base,
                        curve: AppMotion.brand,
                        left: (index < 0 ? 0 : index) * slotWidth,
                        width: slotWidth,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.text.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final item in items)
                            Expanded(
                              child: _MenuBarButton(
                                icon: item.icon,
                                label: item.label,
                                selected: item.section == current,
                                onPressed: () => onSelect(item.section),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuBarButton extends StatefulWidget {
  const _MenuBarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_MenuBarButton> createState() => _MenuBarButtonState();
}

class _MenuBarButtonState extends State<_MenuBarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? AppColors.text : AppColors.brand600;
    return Tooltip(
      message: widget.label,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.label,
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: _pressed ? AppMotion.fast : AppMotion.slow,
            curve: _pressed ? AppMotion.brand : AppMotion.emphasis,
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.brand,
                child: Icon(widget.icon, color: color, size: 19),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
