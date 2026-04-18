import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_translations.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/utils/sync_provider.dart';
import '../../core/widgets/app_bar_actions.dart';

/// Offline-first cloud sync settings.
class SettingsSyncScreen extends StatefulWidget {
  const SettingsSyncScreen({super.key});

  @override
  State<SettingsSyncScreen> createState() => _SettingsSyncScreenState();
}

class _SettingsSyncScreenState extends State<SettingsSyncScreen> {
  bool _wifiOnly = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  void _load() {
    final repo = context.read<AppProvider>().repo;
    setState(() => _wifiOnly = repo.getSettingsSyncWifiOnly());
  }

  Future<void> _setWifiOnly(bool value) async {
    await context.read<AppProvider>().repo.setSettingsSyncWifiOnly(value);
    setState(() => _wifiOnly = value);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncNow(String localeCode) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final summary = await context.read<SyncProvider>().syncNow();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            summary == null
                ? AppTranslations.tr(localeCode, 'syncAuthRequired')
                : '${AppTranslations.tr(localeCode, 'syncSuccess')} '
                      '(${summary.uploaded}/${summary.downloaded}/${summary.merged})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppTranslations.tr(localeCode, 'syncError')}: $e'),
        ),
      );
    }
  }

  Future<void> _signIn(String localeCode) async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.tr(localeCode, 'syncMissingCredentials'),
          ),
        ),
      );
      return;
    }
    try {
      await context.read<SyncProvider>().signIn(
        email: email,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.tr(localeCode, 'syncSignedIn'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppTranslations.tr(localeCode, 'syncError')}: $e'),
        ),
      );
    }
  }

  Future<void> _signUp(String localeCode) async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.tr(localeCode, 'syncMissingCredentials'),
          ),
        ),
      );
      return;
    }
    try {
      final activeSession = await context.read<SyncProvider>().signUp(
        email: email,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.tr(
              localeCode,
              activeSession ? 'syncAccountCreated' : 'syncCheckEmail',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppTranslations.tr(localeCode, 'syncError')}: $e'),
        ),
      );
    }
  }

  Future<void> _signOut(String localeCode) async {
    await context.read<SyncProvider>().signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppTranslations.tr(localeCode, 'syncSignedOut'))),
    );
  }

  String _formatDate(DateTime? date, String localeCode) {
    if (date == null) return AppTranslations.tr(localeCode, 'syncNever');
    return DateFormat('dd.MM.yyyy HH:mm', localeCode).format(date.toLocal());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context
        .watch<LocaleProvider>()
        .effectiveLocale
        .languageCode;
    final syncProvider = context.watch<SyncProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr(localeCode, 'settingsSync')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [AppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.tr(localeCode, 'syncStatusTitle'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (!syncProvider.configured) ...[
                    Text(AppTranslations.tr(localeCode, 'syncNotConfigured')),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.tr(localeCode, 'syncConfigHint'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    _infoRow(
                      context,
                      AppTranslations.tr(localeCode, 'syncConnection'),
                      syncProvider.online
                          ? AppTranslations.tr(localeCode, 'syncOnline')
                          : AppTranslations.tr(localeCode, 'syncOffline'),
                    ),
                    _infoRow(
                      context,
                      AppTranslations.tr(localeCode, 'syncAccount'),
                      syncProvider.signedIn
                          ? (syncProvider.signedInEmail ?? '-')
                          : AppTranslations.tr(localeCode, 'syncNotSignedIn'),
                    ),
                    _infoRow(
                      context,
                      AppTranslations.tr(localeCode, 'syncLastSync'),
                      _formatDate(syncProvider.lastSyncAt, localeCode),
                    ),
                    if (syncProvider.lastError != null &&
                        syncProvider.lastError!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${AppTranslations.tr(localeCode, 'syncLastError')}: ${syncProvider.lastError}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: !syncProvider.configured
                  ? Text(AppTranslations.tr(localeCode, 'syncConfigHint'))
                  : !syncProvider.signedIn
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppTranslations.tr(localeCode, 'syncAuthTitle'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: AppTranslations.tr(localeCode, 'email'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: AppTranslations.tr(
                              localeCode,
                              'syncPassword',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppTranslations.tr(localeCode, 'syncMergeHint'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: syncProvider.syncing
                                    ? null
                                    : () => _signUp(localeCode),
                                child: Text(
                                  AppTranslations.tr(
                                    localeCode,
                                    'syncCreateAccount',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: syncProvider.syncing
                                    ? null
                                    : () => _signIn(localeCode),
                                child: Text(
                                  AppTranslations.tr(localeCode, 'syncSignIn'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppTranslations.tr(localeCode, 'syncActionsTitle'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed:
                              syncProvider.syncing || !syncProvider.signedIn
                              ? null
                              : () => _syncNow(localeCode),
                          icon: syncProvider.syncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                            AppTranslations.tr(
                              localeCode,
                              'settingsSyncManual',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: syncProvider.signedIn
                              ? () => _signOut(localeCode)
                              : null,
                          icon: const Icon(Icons.logout),
                          label: Text(
                            AppTranslations.tr(localeCode, 'syncSignOut'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: Text(
                AppTranslations.tr(localeCode, 'settingsSyncWifiOnly'),
              ),
              subtitle: Text(AppTranslations.tr(localeCode, 'syncWifiHint')),
              value: _wifiOnly,
              onChanged: _setWifiOnly,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
