import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_locales.dart';
import '../localization/tr_extension.dart';
import '../utils/locale_provider.dart';
import '../utils/theme_provider.dart';

/// Tema, Ayarlar ve Çeviri ikonları - tüm sayfalarda kullanılır
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    context.watch<ThemeProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            context.watch<ThemeProvider>().isDark ? Icons.light_mode : Icons.dark_mode,
          ),
          tooltip: context.tr('themeMode'),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: context.tr('settings'),
          onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed('/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.translate),
          tooltip: context.tr('selectLanguage'),
          onPressed: () => _showLanguageMenu(context),
        ),
      ],
    );
  }

  void _showLanguageMenu(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final currentCode = localeProvider.effectiveLocale.languageCode;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('selectLanguage'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...AppLocales.codes.map((code) {
                final isSelected = currentCode == code;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(AppLocales.label(code)),
                  onTap: () async {
                    await localeProvider.setLocale(Locale(code));
                    if (context.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
