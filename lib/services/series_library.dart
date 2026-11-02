import '../models/saved_series.dart';
import '../models/series.dart';
import 'storage_service.dart';

/// The user's saved series ("Mes séries"), most recent first. Every change
/// is written through to [StorageService].
class SeriesLibrary {
  SeriesLibrary(this._storage);

  final StorageService _storage;
  List<SavedSeries> _items = [];
  int _idSeq = 0;

  List<SavedSeries> get items => List.unmodifiable(_items);

  Future<void> load() async => _items = await _storage.loadLibrary();

  /// Names are compared trimmed and case-insensitively.
  static String normalize(String name) => name.trim().toLowerCase();

  SavedSeries? byName(String name) {
    final key = normalize(name);
    for (final s in _items) {
      if (normalize(s.name) == key) return s;
    }
    return null;
  }

  /// Saves [series] under [name]. A series with the same name is replaced
  /// in place; otherwise the new one goes first.
  Future<SavedSeries> save(String name, Series series) async {
    final existing = byName(name);
    final saved = existing == null
        ? SavedSeries(id: _nextId(), name: name.trim(), series: series)
        : existing.copyWith(name: name.trim(), series: series);
    _items = existing == null
        ? [saved, ..._items]
        : [for (final s in _items) s.id == saved.id ? saved : s];
    await _persist();
    return saved;
  }

  /// Returns false (and changes nothing) if another series has that name.
  Future<bool> rename(String id, String name) async {
    final clash = byName(name);
    if (clash != null && clash.id != id) return false;
    _items = [
      for (final s in _items) s.id == id ? s.copyWith(name: name.trim()) : s,
    ];
    await _persist();
    return true;
  }

  /// Removes the series and returns its former position (for undo), or -1.
  Future<int> delete(String id) async {
    final index = _items.indexWhere((s) => s.id == id);
    if (index < 0) return -1;
    _items = [..._items]..removeAt(index);
    await _persist();
    return index;
  }

  /// Puts back a series removed by [delete].
  Future<void> restore(SavedSeries saved, int index) async {
    _items = [..._items]..insert(index.clamp(0, _items.length), saved);
    await _persist();
  }

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  Future<void> _persist() => _storage.saveLibrary(_items);
}
