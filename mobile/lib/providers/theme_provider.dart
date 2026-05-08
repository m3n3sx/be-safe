import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String id;
  final String name;
  final Color seedColor;
  final String emoji;
  const AppTheme(this.id, this.name, this.seedColor, this.emoji);
}

const appThemes = [
  AppTheme('blue', 'Niebieski', Color(0xFF2979FF), '🔵'),
  AppTheme('red', 'Czerwony', Color(0xFFD32F2F), '🔴'),
  AppTheme('green', 'Zielony', Color(0xFF388E3C), '🟢'),
  AppTheme('purple', 'Fioletowy', Color(0xFF7B1FA2), '🟣'),
  AppTheme('orange', 'Pomarańczowy', Color(0xFFE65100), '🟠'),
  AppTheme('teal', 'Morski', Color(0xFF00897B), '🩵'),
];

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  String _themeId = 'blue';

  ThemeMode get mode => _mode;
  String get themeId => _themeId;
  Color get seedColor => appThemes.firstWhere((t) => t.id == _themeId, orElse: () => appThemes[0]).seedColor;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('theme_mode') ?? 'dark';
    _mode = switch (v) { 'light' => ThemeMode.light, 'system' => ThemeMode.system, _ => ThemeMode.dark };
    _themeId = prefs.getString('theme_color') ?? 'blue';
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode; notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) { ThemeMode.light => 'light', ThemeMode.system => 'system', _ => 'dark' });
  }

  Future<void> setThemeColor(String id) async {
    _themeId = id; notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_color', id);
  }
}
