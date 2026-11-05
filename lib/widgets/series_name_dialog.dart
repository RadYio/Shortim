import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
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
  /// Tongue-in-cheek name ideas shown as the field's hint, one drawn at
  /// random each time the dialog opens. Humour, not UI copy: kept here
  /// rather than in the .arb files.
  static const _funnyPlaceholdersFr = [
    'Projet Abdos de Fer',
    'Opération Transpi',
    'Les Cuisses en Feu',
    'Mission Essoufflé',
    'Combat du Mardi',
    'Défi Jambes Flageolantes',
    'Le Retour du Squat',
    'Panique au Gymnase',
    'Sueur et Gloire',
    'Les Bras Tremblants',
    'Expédition Cardio',
    'Dernière Ligne Droite (ou pas)',
  ];
  static const _funnyPlaceholdersEn = [
    'Project Iron Abs',
    'Operation Sweat',
    'Thighs on Fire',
    'Mission Out of Breath',
    'Tuesday Showdown',
    'Jelly Legs Challenge',
    'Return of the Squat',
    'Panic at the Gym',
    'Sweat and Glory',
    'The Shaky Arms',
    'Cardio Expedition',
    'Final Stretch (or Not)',
  ];

  /// Drawn once per dialog, not per build, so the hint doesn't change while
  /// the user is typing. The language is picked in [build] (the locale isn't
  /// readable yet when this initialises).
  late final int _placeholderIndex = Random().nextInt(
    _funnyPlaceholdersFr.length,
  );

  String _placeholder(BuildContext context) {
    final list = Localizations.localeOf(context).languageCode == 'fr'
        ? _funnyPlaceholdersFr
        : _funnyPlaceholdersEn;
    return list[_placeholderIndex % list.length];
  }

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
        style: TextStyle(fontSize: 17, color: AppColors.text),
        decoration: InputDecoration(
          hintText: _placeholder(context),
          helperText: clashes && !renaming ? context.l10n.replaceHelper : null,
          errorText: clashes && renaming ? context.l10n.nameTaken : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: _canConfirm ? _confirm : null,
          child: Text(
            clashes && !renaming ? context.l10n.replace : widget.confirmLabel,
          ),
        ),
      ],
    );
  }
}
