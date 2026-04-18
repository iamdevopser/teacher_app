import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_locales.dart';
import '../../core/localization/app_translations.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../core/utils/locale_provider.dart';

/// İlk açılış: dil seçimi (varsayılan İngilizce)
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = AppLocales.defaultLocale;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<LocaleProvider>();
    if (provider.locale != null && _selectedCode == AppLocales.defaultLocale) {
      _selectedCode = provider.locale!.languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final localeCode = localeProvider.locale?.languageCode ?? _selectedCode;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: canPop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(AppTranslations.tr(localeCode, 'selectLanguage')),
              actions: const [AppBarActions()],
            )
          : AppBar(
              title: Text(AppTranslations.tr(localeCode, 'selectLanguage')),
              actions: const [AppBarActions()],
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                AppTranslations.tr(localeCode, 'appTitle'),
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                AppTranslations.tr(localeCode, 'selectLanguage'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AppLocales.codes.map((code) {
                  return DropdownMenuItem(
                    value: code,
                    child: Text(AppLocales.label(code)),
                  );
                }).toList(),
                onChanged: (code) {
                  if (code != null) setState(() => _selectedCode = code);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await localeProvider.setLocale(Locale(_selectedCode));
                  if (context.mounted) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacementNamed('/setup');
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(AppTranslations.tr(localeCode, 'continue')),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
