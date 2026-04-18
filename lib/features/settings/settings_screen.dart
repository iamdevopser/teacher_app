import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_version.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../setup/language_screen.dart';
import 'settings_module_menu_screen.dart';
import 'settings_sync_screen.dart';

/// Ayarlar ekranı
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().effectiveLocale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr(localeCode, 'settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [AppBarActions()],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppTranslations.tr(localeCode, 'selectLanguage')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppTranslations.tr(localeCode, 'teacherName')),
            subtitle: Text(context.watch<AppProvider>().profile?.teacherName ?? '-'),
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: Text(AppTranslations.tr(localeCode, 'settingsModuleManager')),
            subtitle: Text(AppTranslations.tr(localeCode, 'settingsModuleManagerSubtitle')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsModuleMenuScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(AppTranslations.tr(localeCode, 'settingsSync')),
            subtitle: Text(AppTranslations.tr(localeCode, 'settingsSyncSubtitle')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsSyncScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppTranslations.tr(localeCode, 'settingsVersion')),
            subtitle: Text('$appVersion ($appBuildNumber)'),
          ),
        ],
      ),
    );
  }
}
