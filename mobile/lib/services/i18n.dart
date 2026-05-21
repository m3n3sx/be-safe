import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Internationalization service. Loads translations from
/// `assets/i18n/strings.json` at startup (call [load] in main()).
///
/// Supported languages: pl (Polish), en (English), uk (Ukrainian).
/// Master translation file format:
/// {
///   "pl": { "key": "Polski tekst", ... },
///   "en": { "key": "English text", ... },
///   "uk": { "key": "Український текст", ... }
/// }
class S {
  static String _lang = 'pl';
  static String get lang => _lang;

  /// Runtime-loaded translation maps. Populated by [load].
  static Map<String, Map<String, String>> _strings = const {};

  /// Loads saved language preference and translation strings from bundle.
  /// Idempotent (safe to call multiple times).
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _lang = p.getString('lang') ?? 'pl';
    if (_strings.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString('assets/i18n/strings.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _strings = decoded.map((lang, table) => MapEntry(
            lang,
            (table as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v.toString())),
          ));
    } catch (_) {
      // Fallback: keep _strings empty; get() will return raw keys.
      _strings = const {};
    }
  }

  static Future<void> setLang(String lang) async {
    _lang = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', lang);
  }

  /// Returns localized string for [key]. Fallback chain: current lang → pl → key.
  static String get(String key) =>
      _strings[_lang]?[key] ?? _strings['pl']?[key] ?? key;

  static List<String> get availableLanguages => const ['pl', 'en', 'uk'];

  static String langName(String code) => switch (code) {
        'pl' => 'Polski',
        'en' => 'English',
        'uk' => 'Українська',
        _ => code,
      };
}
