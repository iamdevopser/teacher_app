import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/app_locales.dart';

/// Manages app locale and persists user selection
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  /// Returns effective locale — defaults to English while prefs load or if unset.
  Locale get effectiveLocale => _locale ?? const Locale(AppLocales.defaultLocale);

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    var code = prefs.getString(AppConstants.localeKey);
    if (code == null || !AppLocales.codes.contains(code)) {
      code = AppLocales.defaultLocale;
      await prefs.setString(AppConstants.localeKey, code);
    }
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocales.codes.contains(locale.languageCode)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.localeKey, locale.languageCode);
    notifyListeners();
  }
}
