import 'package:flutter/material.dart';

import '../models/saved_series.dart';
import '../services/series_library.dart';
import '../theme.dart';

/// Asks for a series name. Returns the trimmed name, or null if cancelled.
///
/// When saving ([renamingId] null), an existing name is allowed and the
/// button turns into "Remplacer". When renaming, another series' name is
/// refused.
Future<String?> showSeriesNameDialog(
  BuildContext context, {
  required SeriesLibrary library,
  required String title,
  required String confirmLabel,
  String initial = '',
  String? renamingId,
}) => showDialog<String>(
  context: context,
  builder: (_) => _SeriesNameDialog(
    library: library,
    title: title,
    confirmLabel: confirmLabel,
    initial: initial,
    renamingId: renamingId,
  ),
);

class _SeriesNameDialog extends StatefulWidget {
  const _SeriesNameDialog({
    required this.library,
    required this.title,
    required this.confirmLabel,
    required this.initial,
    required this.renamingId,
  });

  final SeriesLibrary library;
  final String title;
  final String confirmLabel;
  final String initial;
  final String? renamingId;

  @override
  State<_SeriesNameDialog> createState() => _SeriesNameDialogState();
}

class _SeriesNameDialogState extends State<_SeriesNameDialog> {
  late final _text = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String get _name => _text.text.trim();

  /// Another saved series already uses this name.
  bool get _clashes {
    final other = widget.library.byName(_name);
    return other != null && other.id != widget.renamingId;
  }

  bool get _canConfirm =>
      _name.isNotEmpty && !(_clashes && widget.renamingId != null);

  void _confirm() {
    if (_canConfirm) Navigator.pop(context, _name);
  }

  @override
  Widget build(BuildContext context) {
    final clashes = _name.isNotEmpty && _clashes;
    final renaming = widget.renamingId != null;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: SavedSeries.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 17, color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Muscu1',
          helperText: clashes && !renaming
              ? 'Une série porte déjà ce nom : elle sera remplacée.'
              : null,
          errorText: clashes && renaming ? 'Ce nom est déjà utilisé.' : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _canConfirm ? _confirm : null,
          child: Text(clashes && !renaming ? 'Remplacer' : widget.confirmLabel),
        ),
      ],
    );
  }
}
