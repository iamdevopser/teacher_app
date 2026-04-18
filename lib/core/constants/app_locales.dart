/// Desteklenen diller: sadece Türkçe ve İngilizce
class AppLocales {
  static const Map<String, String> languages = {
    'tr': 'Türkçe',
    'en': 'English',
  };

  static const String defaultLocale = 'en';
  static List<String> get codes => languages.keys.toList();
  static String label(String code) => languages[code] ?? code;
}
