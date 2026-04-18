import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/utils/module_flags_notifier.dart';
import '../../core/widgets/app_bar_actions.dart';

/// extra.md MODÜL 6: Modül Yönetim Paneli.
/// Ayarlar > Modüller: Tüm yeni modüller varsayılan kapalı, bu ekrandan açılır/kapatılır.
class ModuleManagerScreen extends StatelessWidget {
  const ModuleManagerScreen({super.key});

  static String _moduleNameKey(String moduleId) => 'module_$moduleId';

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().effectiveLocale.languageCode;
    final notifier = context.watch<ModuleFlagsNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr(localeCode, 'settingsModuleManager')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [AppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              AppTranslations.tr(localeCode, 'settingsModuleManagerSubtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          ...AppConstants.moduleIds.map((moduleId) {
            final enabled = notifier.isEnabled(moduleId);
            final title = AppTranslations.tr(localeCode, _moduleNameKey(moduleId));
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                title: Text(title),
                value: enabled,
                onChanged: (value) => notifier.setEnabled(moduleId, value),
              ),
            );
          }),
        ],
      ),
    );
  }
}
