/// Lokalna persystencja przypiętych członków rodziny na mapie.
///
/// Użytkownik wybiera maks. 3 osoby których awatary mają być zawsze widoczne
/// na pasku karuzeli (right edge mapy). Pozostali ukryci pod "+N" do bottom
/// sheeta.
library;

import 'package:shared_preferences/shared_preferences.dart';

class PinnedFamilyService {
  static const String _key = 'pinned_family_members_v1';
  static const int maxPinned = 3;

  /// Wczytaj listę przypiętych user_id (max 3).
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const <String>[];
    if (list.length <= maxPinned) return list;
    return list.sublist(0, maxPinned);
  }

  /// Zapisz nową listę (przycięta do maxPinned).
  static Future<void> save(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final clipped = ids.length > maxPinned ? ids.sublist(0, maxPinned) : ids;
    await prefs.setStringList(_key, clipped);
  }

  /// Przełącz pin dla user_id.
  ///
  /// Zwraca nową listę po toggle. Jeśli była przypięta — usuwa. Jeśli nie była
  /// i jest miejsce (<maxPinned) — dodaje na koniec. Jeśli nie ma miejsca —
  /// zwraca listę bez zmian (caller pokaże SnackBar).
  static Future<List<String>> toggle(String userId) async {
    final current = await load();
    final next = [...current];
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      if (next.length >= maxPinned) {
        return current; // bez zmian
      }
      next.add(userId);
    }
    await save(next);
    return next;
  }

  /// Czy lista jest pełna (max 3)?
  static Future<bool> isFull() async {
    final list = await load();
    return list.length >= maxPinned;
  }
}
