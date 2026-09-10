import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale extends ChangeNotifier {
  AppLocale._();
  static final AppLocale instance = AppLocale._();

  static const supportedLanguageCodes = <String>{'en', 'hi', 'mr', 'ta', 'bn'};
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedCode = preferences.getString('language_code')?.toLowerCase();
      final languageCode = _normalize(storedCode);
      if (languageCode != _locale.languageCode) {
        _locale = Locale(languageCode);
        notifyListeners();
      }
    } catch (_) {
      // Keep English as a safe default if preferences are unavailable.
      _locale = const Locale('en');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    final safeCode = _normalize(languageCode);
    if (_locale.languageCode != safeCode) {
      _locale = Locale(safeCode);
      notifyListeners();
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('language_code', safeCode);
    } catch (_) {
      // The in-memory locale still updates even when persistence is unavailable.
    }
  }

  static String _normalize(String? languageCode) =>
      supportedLanguageCodes.contains(languageCode) ? languageCode! : 'en';
}