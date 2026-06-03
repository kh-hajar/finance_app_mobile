// Contrôleur gérant le thème de l'application (clair / sombre)

import 'package:flutter/material.dart';
import '../services/pref_service.dart';

class ThemeController extends ChangeNotifier {
  final PrefService _prefs = PrefService();

  bool _isDarkMode = false;
  String _currency = 'MAD';

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;

  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    _isDarkMode = await _prefs.getDarkMode();
    _currency = await _prefs.getCurrency();
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    await _prefs.saveCurrency(currency);
    notifyListeners();
  }
}