import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'api_client.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isAr => _locale.languageCode == 'ar';

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _locale = Locale(saved);
      NotificationService.setLocaleAr(_locale.languageCode == 'ar');
      apiClient.setLocale(_locale.languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    NotificationService.setLocaleAr(locale.languageCode == 'ar');
    apiClient.setLocale(locale.languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> toggle() async {
    await setLocale(isAr ? const Locale('en') : const Locale('ar'));
  }
}
