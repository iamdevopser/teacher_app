import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_translations.dart';
import '../utils/locale_provider.dart';

/// Extension for easy translation access via BuildContext.
/// Usage: context.tr('key')
extension TrExtension on BuildContext {
  String tr(String key) {
    final locale = read<LocaleProvider>().effectiveLocale.languageCode;
    return AppTranslations.tr(locale, key);
  }
}
