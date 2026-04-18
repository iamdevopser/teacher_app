import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_translations.dart';
import 'core/widgets/app_bar_actions.dart';
import 'core/theme/app_theme.dart';
import 'data/local_db/hive_service.dart';
import 'core/utils/app_provider.dart';
import 'core/utils/locale_provider.dart';
import 'core/utils/theme_provider.dart';
import 'core/utils/module_flags_notifier.dart';
import 'core/utils/sync_provider.dart';
import 'features/setup/language_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/main_shell/main_shell_screen.dart';
import 'features/settings/settings_screen.dart';

bool _isCompactDevice() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final logicalSize = view.physicalSize / view.devicePixelRatio;
  return logicalSize.shortestSide < 600;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await HiveService.init().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Hive init timeout'),
    );
  } catch (e) {
    debugPrint('Hive init: $e');
    startupError = e.toString();
  }
  runApp(
    ProviderScope(
      child: TeacherPlannerApp(startupError: startupError),
    ),
  );
}

class TeacherPlannerApp extends StatelessWidget {
  const TeacherPlannerApp({super.key, this.startupError});

  final String? startupError;

  @override
  Widget build(BuildContext context) {
    final compact = _isCompactDevice();
    if (startupError != null) {
      return MaterialApp(
        title: 'Teacher Planner',
        theme: AppTheme.lightThemeFor(compact: compact),
        darkTheme: AppTheme.darkThemeFor(compact: compact),
        debugShowCheckedModeBanner: false,
        home: _StartupErrorScreen(error: startupError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadLocale()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProxyProvider<AppProvider, SyncProvider>(
          create: (_) => SyncProvider()..init(),
          update: (_, appProvider, syncProvider) {
            syncProvider!.attachAppProvider(appProvider);
            return syncProvider;
          },
        ),
        ChangeNotifierProxyProvider<SyncProvider, ModuleFlagsNotifier>(
          create: (_) => ModuleFlagsNotifier()..load(),
          update: (_, syncProvider, notifier) {
            notifier ??= ModuleFlagsNotifier();
            if (syncProvider.dataRevision > 0) {
              notifier.load();
            }
            return notifier;
          },
        ),
      ],
      child: const _AppContent(),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final message = error.toLowerCase().contains('used by another process')
        ? 'Uygulama veritabani baska bir pencere tarafindan kullaniliyor. Diger uygulama pencerelerini kapatip tekrar deneyin.'
        : 'Uygulama veritabani acilamadi. Lutfen uygulamayi kapatip tekrar deneyin.';

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Planner')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storage_rounded, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Baslangic hatasi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  Future<void> _loadApp() async {
    try {
      await context.read<AppProvider>().init().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Init timeout'),
      );
    } catch (e) {
      debugPrint('App init error: $e');
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final compact = _isCompactDevice();
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.ltr, child: child!),
        home: Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.tr('en', 'appTitle')),
            actions: const [AppBarActions()],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.tr('en', 'loading'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final appProvider = context.watch<AppProvider>();

    // Default: English. When locale is null, use English and show main app.
    // User can change language in Settings.
    Widget home;
    // Ana kabuk için dataRevision ile key VERMEYIN: senkron sonrasi yeniden
    // olusturulunca ic Navigator'lar sifirlanir (or. kurs sihirbazi kapanir).
    if (!appProvider.setupComplete) {
      home = const SetupScreen();
    } else {
      home = const MainShellScreen();
    }

    final locale = localeProvider.effectiveLocale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.ltr, child: child!),
      title: AppTranslations.tr(
        localeProvider.effectiveLocale.languageCode,
        'appTitle',
      ),
      theme: AppTheme.lightThemeFor(compact: compact),
      darkTheme: AppTheme.darkThemeFor(compact: compact),
      themeMode: themeProvider.themeMode,
      locale: locale,
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: home,
      routes: {
        '/language': (context) => const LanguageScreen(),
        '/setup': (context) => const SetupScreen(),
        '/dashboard': (context) => const MainShellScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
