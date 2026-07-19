import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopscotch/repositories/config_repository.dart';

enum AppLanguage {
  english('en', 'US', 'English'),
  hindi('hi', 'IN', 'हिन्दी'),
  marathi('mr', 'IN', 'मराठी'),
  gujarati('gu', 'IN', 'ગુજરાતી'),
  tamil('ta', 'IN', 'தமிழ்'),
  telugu('te', 'IN', 'తెలుగు'),
  kannada('kn', 'IN', 'ಕನ್ನಡ'),
  malayalam('ml', 'IN', 'മലയാളം'),
  punjabi('pa', 'IN', 'ਪੰਜਾਬੀ'),
  bengali('bn', 'IN', 'বাংলা'),
  urdu('ur', 'PK', 'اردو'),
  arabic('ar', 'SA', 'العربية'),
  french('fr', 'FR', 'Français'),
  german('de', 'DE', 'Deutsch'),
  spanish('es', 'ES', 'Español'),
  portuguese('pt', 'PT', 'Português'),
  japanese('ja', 'JP', '日本語'),
  chinese('zh', 'CN', '中文'),
  russian('ru', 'RU', 'Русский'),
  // New countries
  malay('ms', 'MY', 'Bahasa Melayu'),
  dutch('nl', 'NL', 'Nederlands');

  final String code;
  final String countryCode;
  final String name;

  const AppLanguage(this.code, this.countryCode, this.name);
  
  Locale get locale => Locale(code, countryCode);
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    state = AppLanguage.values.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', language.code);
    state = language;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

final enabledLanguagesProvider = FutureProvider<List<AppLanguage>>((ref) async {
  final configRepo = ref.watch(configRepositoryProvider);
  final apiLangs = await configRepo.fetchLanguages();
  if (apiLangs.isEmpty) {
    // Default fallback list
    return AppLanguage.values;
  }
  return AppLanguage.values.where((lang) {
    return apiLangs.any((apiLang) =>
        apiLang['code'].toString().toLowerCase() == lang.code.toLowerCase() &&
        apiLang['isEnabled'] == true);
  }).toList();
});
