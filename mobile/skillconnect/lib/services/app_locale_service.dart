import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleService {
  static const _key = 'app_language';
  static final ValueNotifier<Locale?> notifier = ValueNotifier<Locale?>(null);

  static const List<MapEntry<String, String>> languageOptions = [
    MapEntry('en', 'English'),
    MapEntry('hi', 'हिंदी (Hindi)'),
    MapEntry('te', 'తెలుగు (Telugu)'),
    MapEntry('ta', 'தமிழ் (Tamil)'),
    MapEntry('kn', 'ಕನ್ನಡ (Kannada)'),
    MapEntry('mr', 'मराठी (Marathi)'),
    MapEntry('bn', 'বাংলা (Bengali)'),
    MapEntry('gu', 'ગુજરાતી (Gujarati)'),
    MapEntry('pa', 'ਪੰਜਾਬੀ (Punjabi)'),
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = _localeFromCode(prefs.getString(_key));
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    notifier.value = _localeFromCode(code);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'en';
  }

  static Locale? _localeFromCode(String? code) {
    switch (code) {
      case 'en':
      case 'hi':
      case 'te':
      case 'ta':
      case 'kn':
      case 'mr':
      case 'bn':
      case 'gu':
      case 'pa':
        return Locale(code!);
      default:
        return null;
    }
  }

  static String labelFor(String code) {
    for (final option in languageOptions) {
      if (option.key == code) return option.value;
    }
    return 'English';
  }
}
