import 'package:flutter/material.dart';

/// A confirm/cancel dialog styled like the rest of Shortim — the same pill
/// [OutlinedButton]/[FilledButton] pair used everywhere else in the app
/// (Pause/Arrêter, Continuer/Démarrer…), full-width and stacked side by
/// side, instead of the generic `AlertDialog` default of two bare inline
/// text links. Visually it's still an `AlertDialog` (so it inherits
/// `DialogThemeData` — background, corner radius, title/content type
/// styles — from `buildTheme`), only the actions row is reshaped.
///
/// Returns `true` if [confirmLabel] was tapped, `false` for [cancelLabel]
/// or a dismissal, exactly like a bare `showDialog<bool>(AlertDialog(...))`
/// call would.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.body,
    this.destructive = false,
  });

  final String title;
  final String? body;
  final String cancelLabel;
  final String confirmLabel;

  /// Whether [confirmLabel] ends the current run/series (stop, delete…):
  /// swaps which action is filled vs outlined, so the button that carries
  /// more visual weight is always the one the user is more likely to want,
  /// and an irreversible action is never the loud default.
  final bool destructive;

  /// Convenience wrapper around `showDialog<bool>` — the common case.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required String cancelLabel,
    String? body,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // The dialog box is narrower than a full-width screen button (the
    // theme's default button size/weight, tuned for 175px+ wide buttons),
    // so two side by side need a tighter, smaller-type style to avoid
    // wrapping ("Reprendre" at the default 17px/600 does not fit ~130px).
    const buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
    // The button carrying more visual weight (filled) is always the one
    // the user is more likely to want: for a destructive confirm, that's
    // staying put (cancel), not the irreversible action.
    final cancelButton = destructive
        ? FilledButton(
            style: buttonStyle,
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        : OutlinedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
    final confirmButton = destructive
        ? OutlinedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        : FilledButton(
            style: buttonStyle,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(title),
      content: body == null ? null : Text(body!),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      // A single "action" spanning the full width, so both buttons keep
      // the app's usual pill shape instead of OverflowBar's cramped
      // inline text links.
      actions: [
        Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: 10),
            Expanded(child: confirmButton),
          ],
        ),
      ],
    );
  }
}
