import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/saved_series.dart';
import '../services/series_library.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import 'floating_menu_bar.dart';
import '../screens/library_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/setup_screen.dart';

/// Lets [AppShell] hand a [LibraryChoice] back into the (always-mounted)
/// setup screen without a Navigator round-trip.
class SetupApplyController {
  ValueChanged<LibraryChoice>? _apply;

  void bind(ValueChanged<LibraryChoice> apply) => _apply = apply;

  void apply(LibraryChoice choice) => _apply?.call(choice);
}

/// Hosts the three sections (chrono / réglages / mes séries) behind one
/// persistent floating bottom menu: it never disappears, a white capsule
/// follows whichever section is current, and it only ever holds
/// navigation, never actions like "Enregistrer" or "Démarrer".
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.sounds, required this.storage});

  final SoundService sounds;
  final StorageService storage;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _section = AppSection.chrono;

  late final SeriesLibrary _library = SeriesLibrary(widget.storage);
  late final Future<void> _libraryReady = _library.load();

  final SetupApplyController _setupController = SetupApplyController();

  @override
  void initState() {
    super.initState();
    _libraryReady.ignore();
  }

  void _goTo(AppSection section) => setState(() => _section = section);

  /// A series picked in "Mes séries" (from the tab, or from Settings'
  /// "Gérer mes séries"): load it into the editor and switch back.
  void _handleChoice(LibraryChoice choice) {
    _setupController.apply(choice);
    _goTo(AppSection.chrono);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _section.index,
            children: [
              SetupScreen(
                sounds: widget.sounds,
                storage: widget.storage,
                library: _library,
                libraryReady: _libraryReady,
                applyController: _setupController,
              ),
              SettingsScreen(
                sounds: widget.sounds,
                library: _library,
                onOpenLibrary: () => _goTo(AppSection.library),
              ),
              LibraryScreen(
                library: _library,
                libraryReady: _libraryReady,
                isActive: _section == AppSection.library,
                onChoice: _handleChoice,
              ),
            ],
          ),
          Positioned(
            left: 56,
            right: 56,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FloatingMenuBar(
                  current: _section,
                  onSelect: _goTo,
                  items: [
                    MenuBarItem(
                      section: AppSection.settings,
                      icon: Icons.settings_outlined,
                      label: context.l10n.settings,
                    ),
                    MenuBarItem(
                      section: AppSection.chrono,
                      icon: Icons.timer_outlined,
                      label: context.l10n.chronoTab,
                    ),
                    MenuBarItem(
                      section: AppSection.library,
                      icon: Icons.bookmarks_outlined,
                      label: context.l10n.mySeries,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
