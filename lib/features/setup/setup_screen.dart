import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_translations.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../data/models/teacher_profile.dart';
import '../main_shell/main_shell_screen.dart';

/// Öğretmen profil kurulumu
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  String? _guidanceClass;
  final List<String> _classesTaught = [];
  final List<String> _allClasses = AppConstants.allClasses;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  void _showClassesPicker(BuildContext context, String localeCode) {
    var selected = List<String>.from(_classesTaught);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx3, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.tr(localeCode, 'selectClasses'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(AppTranslations.tr(localeCode, 'cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _classesTaught
                              ..clear()
                              ..addAll(selected));
                            Navigator.pop(ctx);
                          },
                          child: Text(AppTranslations.tr(localeCode, 'continue')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _allClasses.length,
                  itemBuilder: (_, i) {
                    final c = _allClasses[i];
                    final isSelected = selected.contains(c);
                    return CheckboxListTile(
                      title: Text(c),
                      value: isSelected,
                      onChanged: (_) {
                        setModalState(() {
                          if (isSelected) {
                            selected.remove(c);
                          } else {
                            selected.add(c);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().effectiveLocale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr(localeCode, 'appTitle')),
        actions: const [AppBarActions()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                AppTranslations.tr(localeCode, 'teacherName'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: AppTranslations.tr(localeCode, 'teacherName'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppTranslations.tr(localeCode, 'schoolName'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _schoolCtrl,
                decoration: InputDecoration(
                  hintText: AppTranslations.tr(localeCode, 'schoolName'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppTranslations.tr(localeCode, 'guidanceClass'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _guidanceClass,
                decoration: InputDecoration(
                  hintText: AppTranslations.tr(localeCode, 'selectGuidanceClass'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(AppTranslations.tr(localeCode, 'select'))),
                  ..._allClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() => _guidanceClass = v),
              ),
              const SizedBox(height: 20),
              Text(
                AppTranslations.tr(localeCode, 'classesTaught'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showClassesPicker(context, localeCode),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: _classesTaught.isEmpty
                        ? AppTranslations.tr(localeCode, 'selectClasses')
                        : '${_classesTaught.length} ${AppTranslations.tr(localeCode, 'classesSelected')}',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _classesTaught.isEmpty
                        ? ''
                        : (_classesTaught.length <= 5
                            ? _classesTaught.join(', ')
                            : '${_classesTaught.length} ${AppTranslations.tr(localeCode, 'classesCountLabel')}: ${_classesTaught.take(3).join(', ')}...'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  final school = _schoolCtrl.text.trim();

                  if (name.isEmpty || school.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppTranslations.tr(localeCode, 'requiredFields'))),
                    );
                    return;
                  }

                  if (_classesTaught.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppTranslations.tr(localeCode, 'selectAtLeastOneClass'))),
                    );
                    return;
                  }

                  try {
                    final profile = TeacherProfile(
                      teacherName: name,
                      schoolName: school,
                      classesTaught: List.from(_classesTaught),
                      guidanceClass: _guidanceClass,
                    );
                    await context.read<AppProvider>().completeSetup(profile);
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShellScreen()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${AppTranslations.tr(localeCode, 'error')}: $e')),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(AppTranslations.tr(localeCode, 'continue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
