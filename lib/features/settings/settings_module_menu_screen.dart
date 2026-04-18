import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';

/// extra.md: Modül / Menü Yönetimi – Online ders özellikleri açık/kapalı
class SettingsModuleMenuScreen extends StatefulWidget {
  const SettingsModuleMenuScreen({super.key});

  @override
  State<SettingsModuleMenuScreen> createState() => _SettingsModuleMenuScreenState();
}

class _SettingsModuleMenuScreenState extends State<SettingsModuleMenuScreen> {
  bool _onlineLessonFeatures = true;

  void _load() {
    final repo = context.read<AppProvider>().repo;
    setState(() {
      _onlineLessonFeatures = repo.getSettingsOnlineLessonFeatures();
    });
  }

  Future<void> _setOnlineLessonFeatures(bool value) async {
    await context.read<AppProvider>().repo.setSettingsOnlineLessonFeatures(value);
    if (mounted) {
      setState(() => _onlineLessonFeatures = value);
      context.read<AppProvider>().refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().effectiveLocale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr(localeCode, 'settingsModuleManager')),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: const [AppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: Text(AppTranslations.tr(localeCode, 'settingsOnlineLessonFeatures')),
              value: _onlineLessonFeatures,
              onChanged: _setOnlineLessonFeatures,
            ),
          ),
        ],
      ),
    );
  }
}
