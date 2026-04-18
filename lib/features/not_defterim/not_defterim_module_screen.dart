import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/tr_extension.dart';
import '../../core/widgets/app_bar_actions.dart';
import 'not_defterim_calculator.dart';
import 'not_defterim_export_service.dart';
import 'not_defterim_models.dart';
import 'not_defterim_points_provider.dart';
import 'not_defterim_repository.dart';

class NotDefterimModuleScreen extends ConsumerStatefulWidget {
  const NotDefterimModuleScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onSyncedTabIndex,
  });

  /// Kenar çubuğu ile aynı sıra (0–6).
  final int initialTabIndex;

  /// TabBar ile seçilen sekmeyi ana kabuğa bildirir (kenar çubuğu vurgusu).
  final void Function(int tabIndex)? onSyncedTabIndex;

  @override
  ConsumerState<NotDefterimModuleScreen> createState() => _NotDefterimModuleScreenState();
}

class _NotDefterimModuleScreenState extends ConsumerState<NotDefterimModuleScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabTitleKeys = [
    'notDefterimTabSetup',
    'notDefterimTabClasses',
    'notDefterimTabStudents',
    'notDefterimTabAddPoints',
    'notDefterimTabPoints',
    'notDefterimTabPeriodReport',
    'notDefterimTabExport',
  ];

  late final TabController _tabController;

  /// Kabuktan [initialTabIndex] ile gelen atlarda dinleyiciyi sustur (setState döngüsü yok).
  bool _suppressShellTabCallback = false;

  NotDefterimRepository get _repo => ref.read(notDefterimRepositoryProvider);

  List<NotDefterimClass> _classes = const [];
  List<NotDefterimStudent> _students = const [];
  List<NotDefterimPointType> _pointTypes = const [];

  String? _selectedClassId;

  // Daily / Period settings
  int _schoolYearStart = _initialSchoolYearStart();
  late DateTime _selectedDate;

  void _onTabControllerTick() {
    if (_suppressShellTabCallback) return;
    if (_tabController.indexIsChanging) return;
    if (!mounted) return;
    widget.onSyncedTabIndex?.call(_tabController.index);
  }

  @override
  void initState() {
    super.initState();
    final idx = widget.initialTabIndex.clamp(0, _tabTitleKeys.length - 1);
    _tabController = TabController(
      length: _tabTitleKeys.length,
      vsync: this,
      initialIndex: idx,
    );
    _tabController.addListener(_onTabControllerTick);
    _selectedDate = DateTime.now();
    _reload();
  }

  @override
  void didUpdateWidget(covariant NotDefterimModuleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      final idx = widget.initialTabIndex.clamp(0, _tabController.length - 1);
      if (_tabController.index != idx) {
        _suppressShellTabCallback = true;
        try {
          // jumpTo() tüm SDK sürümlerinde yok; index ataması sidebar senkronu için yeterli.
          _tabController.index = idx;
        } finally {
          _suppressShellTabCallback = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerTick);
    _tabController.dispose();
    super.dispose();
  }

  static int _initialSchoolYearStart() {
    final now = DateTime.now();
    return NotDefterimCalculator.schoolYearStartYearForDate(now);
  }

  Future<void> _reload() async {
    final classes = _repo.getClasses();
    final students = _repo.getStudents();
    final pointTypes = _repo.getPointTypes();

    setState(() {
      _classes = classes;
      _students = students;
      _pointTypes = pointTypes;
      _selectedClassId ??= classes.isNotEmpty ? classes.first.id : null;
    });
  }

  NotDefterimClass? get _selectedClass =>
      _classes.firstWhere((c) => c.id == _selectedClassId, orElse: () => _classes.first);

  List<NotDefterimStudent> get _studentsOfSelectedClass =>
      _repo.getStudentsByClass(_selectedClassId ?? '');

  void _ensureValidSelection() {
    if (_selectedClassId == null && _classes.isNotEmpty) {
      _selectedClassId = _classes.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureValidSelection();
    final dailyEntries = ref.watch(notDefterimDailyEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notDefterim')),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final k in _tabTitleKeys) Tab(text: context.tr(k)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SetupTab(
            key: ValueKey(_pointTypes.length),
            pointTypes: _pointTypes,
            onChanged: () async => _reload(),
          ),
          _ClassesTab(
            classes: _classes,
            onChanged: () async => _reload(),
            onSelectClass: (id) => setState(() => _selectedClassId = id),
          ),
          _StudentsTab(
            classes: _classes,
            students: _students,
            selectedClassId: _selectedClassId,
            onChanged: () async => _reload(),
            onSelectClass: (id) => setState(() => _selectedClassId = id),
          ),
          _DailyPointsTab(
            repo: _repo,
            pointTypes: _pointTypes,
            classes: _classes,
            students: _students,
            selectedClassId: _selectedClassId,
            schoolYearStart: _schoolYearStart,
            selectedDate: _selectedDate,
            onSelectDate: (d) => setState(() => _selectedDate = d),
            onSelectSchoolYearStart: (y) => setState(() => _schoolYearStart = y),
            onSelectClass: (id) => setState(() => _selectedClassId = id),
            onSaved: () async {
              ref.read(notDefterimDailyRevisionProvider.notifier).bump();
            },
          ),
          _PointsMatrixTab(
            classes: _classes,
            students: _students,
            pointTypes: _pointTypes,
            selectedClassId: _selectedClassId,
            schoolYearStart: _schoolYearStart,
          ),
          _PeriodReportsTab(
            repo: _repo,
            classes: _classes,
            students: _students,
            pointTypes: _pointTypes,
            selectedClassId: _selectedClassId,
            schoolYearStart: _schoolYearStart,
            dailyEntries: dailyEntries,
            onSelectClass: (id) => setState(() => _selectedClassId = id),
            onSelectSchoolYearStart: (y) => setState(() => _schoolYearStart = y),
          ),
          _ExportsTab(
            repo: _repo,
            classes: _classes,
            students: _students,
            pointTypes: _pointTypes,
            selectedClassId: _selectedClassId,
            schoolYearStart: _schoolYearStart,
            onSaved: () async => _reload(),
          ),
        ],
      ),
    );
  }
}

class _SetupTab extends StatefulWidget {
  final List<NotDefterimPointType> pointTypes;
  final Future<void> Function() onChanged;

  const _SetupTab({
    required super.key,
    required this.pointTypes,
    required this.onChanged,
  });

  @override
  State<_SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends State<_SetupTab> {
  final _repo = NotDefterimRepository();

  Future<void> _addOrEditPointType({NotDefterimPointType? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    NotDefterimPointKind kind =
        existing?.kind ?? NotDefterimPointKind.daily;
    bool affectsFinal =
        existing?.affectsFinal ?? (kind != NotDefterimPointKind.daily);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Puan Türü Ekle' : 'Puan Türü Düzenle'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<NotDefterimPointKind>(
                value: kind,
                decoration: const InputDecoration(labelText: 'Tür'),
                items: const [
                  DropdownMenuItem(
                    value: NotDefterimPointKind.daily,
                    child: Text('Günlük'),
                  ),
                  DropdownMenuItem(
                    value: NotDefterimPointKind.homework,
                    child: Text('Ödev'),
                  ),
                  DropdownMenuItem(
                    value: NotDefterimPointKind.exam,
                    child: Text('Sınav'),
                  ),
                ],
                onChanged: (v) => kind = v ?? NotDefterimPointKind.daily,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (ctx, setModalState) {
                  return CheckboxListTile(
                    value: affectsFinal,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Final nota etki eder (1-10 girilir)'),
                    onChanged: (v) => setModalState(() => affectsFinal = v ?? false),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx, {
                'name': name,
                'kind': kind,
                'affectsFinal': affectsFinal,
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final updatedName = result['name'] as String;
    final updatedKind = result['kind'] as NotDefterimPointKind;
    final updatedAffectsFinal = result['affectsFinal'] as bool? ?? false;

    // `widget.pointTypes` ilk yüklemede `const []` gelebilir (Hive boşken).
    // Mutasyon hatası/refresh sorunlarını engellemek için her zaman kopya ile çalışıyoruz.
    final items = widget.pointTypes.toList();
    if (existing == null) {
      items.add(
        NotDefterimPointType(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: updatedName,
          kind: updatedKind,
          affectsFinal: updatedAffectsFinal,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      final idx = items.indexWhere((e) => e.id == existing.id);
      if (idx >= 0) {
        items[idx] = NotDefterimPointType(
          id: existing.id,
          name: updatedName,
          kind: updatedKind,
          affectsFinal: updatedAffectsFinal,
          createdAt: existing.createdAt,
        );
      }
    }
    await _repo.savePointTypes(items);
    // Kaydetme sonrası parent Hive'dan yeniden yükler ve UI otomatik rebuild olur.
    await widget.onChanged();
  }

  Future<void> _deletePointType(NotDefterimPointType p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: Text('${p.name} puan türü silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;

    final items = widget.pointTypes.where((e) => e.id != p.id).toList();
    await _repo.savePointTypes(items);
    // Daily entries: keep values map but they become unused; simple approach.
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final pointTypes = widget.pointTypes;

    return RefreshIndicator(
      onRefresh: widget.onChanged,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Puan türlerini olusturun (onemli: baslangicta varsayilan yok).',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _addOrEditPointType(),
            icon: const Icon(Icons.add),
            label: const Text('Puan Türü Ekle'),
          ),
          const SizedBox(height: 16),
          if (pointTypes.isEmpty)
            const Text('Henüz puan türü yok.')
          else
            ...pointTypes.map(
              (p) => Card(
                child: ListTile(
                  leading: Icon(
                    p.kind == NotDefterimPointKind.daily
                        ? Icons.today
                        : p.kind == NotDefterimPointKind.homework
                            ? Icons.assignment
                            : Icons.quiz,
                  ),
                  title: Text(p.name),
                  subtitle: Text(p.kind == NotDefterimPointKind.daily
                      ? 'Günlük'
                      : p.kind == NotDefterimPointKind.homework
                          ? 'Ödev'
                          : 'Sınav'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _addOrEditPointType(existing: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deletePointType(p),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClassesTab extends StatefulWidget {
  final List<NotDefterimClass> classes;
  final Future<void> Function() onChanged;
  final void Function(String id) onSelectClass;

  const _ClassesTab({
    super.key,
    required this.classes,
    required this.onChanged,
    required this.onSelectClass,
  });

  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  final _repo = NotDefterimRepository();

  Future<void> _addOrEditClass({NotDefterimClass? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Sınıf Ekle' : 'Sınıf Düzenle'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Sınıf Adı'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final v = nameCtrl.text.trim();
              if (v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result == null) return;

    var items = widget.classes.toList();
    if (existing == null) {
      items.add(
        NotDefterimClass(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: result,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      final idx = items.indexWhere((e) => e.id == existing.id);
      if (idx >= 0) {
        items[idx] = NotDefterimClass(
          id: existing.id,
          name: result,
          createdAt: existing.createdAt,
        );
      }
    }
    await _repo.saveClasses(items);
    await widget.onChanged();
  }

  Future<void> _deleteClass(NotDefterimClass c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: Text('${c.name} sınıfı silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.saveClasses(widget.classes.where((e) => e.id != c.id).toList());
    // Note: Students/daily entries remain; simple approach.
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final classes = widget.classes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _addOrEditClass(),
          icon: const Icon(Icons.add),
          label: const Text('Sınıf Ekle'),
        ),
        const SizedBox(height: 16),
        if (classes.isEmpty)
          const Text('Henüz sınıf yok.')
        else
          ...classes.map(
            (c) => Card(
              child: ListTile(
                title: Text(c.name),
                onTap: () => widget.onSelectClass(c.id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _addOrEditClass(existing: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteClass(c),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StudentsTab extends StatefulWidget {
  final List<NotDefterimClass> classes;
  final List<NotDefterimStudent> students;
  final String? selectedClassId;
  final Future<void> Function() onChanged;
  final void Function(String id) onSelectClass;

  const _StudentsTab({
    super.key,
    required this.classes,
    required this.students,
    required this.selectedClassId,
    required this.onChanged,
    required this.onSelectClass,
  });

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  final _repo = NotDefterimRepository();

  NotDefterimClass? get _classItem =>
      widget.classes.firstWhere((c) => c.id == widget.selectedClassId, orElse: () => widget.classes.first);

  List<NotDefterimStudent> get _studentsOfClass =>
      widget.students.where((s) => s.classId == widget.selectedClassId).toList();

  Future<void> _addOrEditStudent({NotDefterimStudent? existing}) async {
    final classId = widget.selectedClassId;
    if (classId == null) return;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Öğrenci Ekle' : 'Öğrenci Düzenle'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'İsim'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final v = nameCtrl.text.trim();
              if (v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result == null) return;

    final items = widget.students.toList();
    if (existing == null) {
      final currentCount = items.where((s) => s.classId == classId).length;
      if (currentCount >= 26) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu sınıfta maksimum 26 öğrenci.')),
        );
        return;
      }

      items.add(
        NotDefterimStudent(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          classId: classId,
          name: result,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      final idx = items.indexWhere((e) => e.id == existing.id);
      if (idx >= 0) {
        items[idx] = NotDefterimStudent(
          id: existing.id,
          classId: existing.classId,
          name: result,
          createdAt: existing.createdAt,
        );
      }
    }
    await _repo.saveStudents(items);
    await widget.onChanged();
  }

  Future<void> _deleteStudent(NotDefterimStudent s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: Text('${s.name} silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.saveStudents(widget.students.where((e) => e.id != s.id).toList());
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classes.isEmpty) {
      return const Center(child: Text('Önce sınıf ekleyin.'));
    }

    final classId = widget.selectedClassId ?? widget.classes.first.id;
    final classItem = widget.classes.firstWhere((c) => c.id == classId);
    final students = widget.students.where((s) => s.classId == classId).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: classId,
                  decoration: const InputDecoration(labelText: 'Sınıf'),
                  items: widget.classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    widget.onSelectClass(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _addOrEditStudent(),
                icon: const Icon(Icons.add),
                label: const Text('Öğrenci Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${classItem.name} - ${students.length}/26', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('Henüz öğrenci yok.'))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(s.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _addOrEditStudent(existing: s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteStudent(s),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DailyPointsTab extends StatefulWidget {
  final NotDefterimRepository repo;
  final List<NotDefterimPointType> pointTypes;
  final List<NotDefterimClass> classes;
  final List<NotDefterimStudent> students;
  final String? selectedClassId;
  final int schoolYearStart;
  final DateTime selectedDate;
  final void Function(DateTime date) onSelectDate;
  final void Function(int yearStart) onSelectSchoolYearStart;
  final void Function(String classId) onSelectClass;
  final Future<void> Function() onSaved;

  const _DailyPointsTab({
    required this.repo,
    required this.pointTypes,
    required this.classes,
    required this.students,
    required this.selectedClassId,
    required this.schoolYearStart,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onSelectSchoolYearStart,
    required this.onSelectClass,
    required this.onSaved,
  });

  @override
  State<_DailyPointsTab> createState() => _DailyPointsTabState();
}

class _DailyPointsTabState extends State<_DailyPointsTab> {
  DateTime? _activeRangeStart;
  DateTime? _activeRangeEnd;

  late String _classId;
  late List<NotDefterimStudent> _studentsOfClass;

  // studentId -> pointTypeId -> controller
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  // studentId -> pointTypeId -> value
  final Map<String, Map<String, double>> _draftValues = {};

  @override
  void didUpdateWidget(covariant _DailyPointsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newClassId = widget.selectedClassId ?? widget.classes.firstOrNull?.id;
    if (newClassId != null && newClassId != _classId) {
      _resetForSelection();
    }
    if (oldWidget.schoolYearStart != widget.schoolYearStart) {
      _resetForSelection();
    }
    final oldSig = oldWidget.pointTypes
        .map((e) => '${e.id}|${e.kind.name}|${e.affectsFinal ? 1 : 0}')
        .toList()
      ..sort();
    final newSig = widget.pointTypes
        .map((e) => '${e.id}|${e.kind.name}|${e.affectsFinal ? 1 : 0}')
        .toList()
      ..sort();
    if (oldSig.join(',') != newSig.join(',')) _resetForSelection();
    if (oldWidget.selectedDate != widget.selectedDate) {
      _resetForSelection();
    }
  }

  @override
  void initState() {
    super.initState();
    _classId = widget.selectedClassId ?? widget.classes.firstOrNull?.id ?? '';
    _studentsOfClass = widget.students.where((s) => s.classId == _classId).toList();
    _applyDateRange();
    _loadControllersFromRepo();
  }

  void _applyDateRange() {
    _activeRangeStart = DateTime(widget.schoolYearStart, 9, 1);
    _activeRangeEnd = DateTime(widget.schoolYearStart + 1, 5, 31);
  }

  Future<void> _loadControllersFromRepo() async {
    for (final s in _studentsOfClass) {
      _draftValues[s.id] = {};
      _controllers[s.id] = {};

      for (final pt in widget.pointTypes) {
        final existing = widget.repo.getDailyEntry(
          classId: _classId,
          dateStr: _dateToStr(widget.selectedDate),
          studentId: s.id,
        );
        final existingValue = existing?.values[pt.id] ?? 0.0;

        final ctrl = TextEditingController(text: existingValue == 0 ? '' : existingValue.toString());
        ctrl.addListener(() {
          final raw = ctrl.text.trim();
          final parsed =
              raw.isEmpty ? 0.0 : double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
          final v = pt.affectsFinal ? parsed.clamp(0.0, 10.0) : parsed.clamp(0.0, 100.0);
          _draftValues[s.id]![pt.id] = v;
        });
        _controllers[s.id]![pt.id] = ctrl;
        _draftValues[s.id]![pt.id] = pt.affectsFinal ? existingValue.clamp(0.0, 10.0) : existingValue.clamp(0.0, 100.0);
      }
    }
  }

  Map<String, double> _collectValuesForStudent(String studentId) {
    final byTypeControllers = _controllers[studentId] ?? const <String, TextEditingController>{};
    final out = <String, double>{};
    for (final pt in widget.pointTypes) {
      final ctrl = byTypeControllers[pt.id];
      final raw = (ctrl?.text ?? '').trim();
      final parsed = raw.isEmpty ? 0.0 : double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
      final v = pt.affectsFinal ? parsed.clamp(0.0, 10.0) : parsed.clamp(0.0, 100.0);
      out[pt.id] = v;
    }
    return out;
  }

  /// Bos alan izinli. Doluysa gecerli sayi ve aralikta olmali.
  static String? _validateScoreText(
    String raw,
    NotDefterimPointType pt, {
    required String fieldLabel,
  }) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t.replaceAll(',', '.'));
    if (v == null) {
      return '$fieldLabel: gecersiz sayi';
    }
    if (pt.affectsFinal) {
      if (v < 0 || v > 10) {
        return '$fieldLabel: 0-10 arasi girin';
      }
    } else {
      if (v < 0 || v > 100) {
        return '$fieldLabel: 0-100 arasi girin';
      }
    }
    return null;
  }

  String? _validateTableForSave() {
    for (final s in _studentsOfClass) {
      for (final pt in widget.pointTypes) {
        final c = _controllers[s.id]?[pt.id];
        final err = _validateScoreText(
          c?.text ?? '',
          pt,
          fieldLabel: '${s.name} • ${pt.name}',
        );
        if (err != null) return err;
      }
    }
    return null;
  }

  String? _validateBulkFields(
    NotDefterimPointType pointType,
    Map<String, TextEditingController> perStudentCtrls,
  ) {
    for (final s in _studentsOfClass) {
      final err = _validateScoreText(
        perStudentCtrls[s.id]!.text,
        pointType,
        fieldLabel: '${s.name} • ${pointType.name}',
      );
      if (err != null) return err;
    }
    return null;
  }

  Future<void> _openBulkEntryPanel(NotDefterimPointType pointType) async {
    final topCtrl = TextEditingController();
    final perStudentCtrls = <String, TextEditingController>{};

    for (final s in _studentsOfClass) {
      final existing = widget.repo.getDailyEntry(
        classId: _classId,
        dateStr: _dateToStr(widget.selectedDate),
        studentId: s.id,
      );
      final v = existing?.values[pointType.id] ?? 0.0;
      perStudentCtrls[s.id] = TextEditingController(text: v == 0 ? '' : v.toString());
    }

    double parseValue(String raw) {
      final t = raw.trim();
      final parsed = t.isEmpty ? 0.0 : double.tryParse(t.replaceAll(',', '.')) ?? 0.0;
      return pointType.affectsFinal ? parsed.clamp(0.0, 10.0) : parsed.clamp(0.0, 100.0);
    }

    if (!mounted) return;
    final rootMessenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Toplu giriş: ${pointType.name}',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      tooltip: 'Kapat',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: topCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Toplu uygula',
                          hintText: pointType.affectsFinal ? '1-10' : '0-100',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: () {
                        final v = parseValue(topCtrl.text);
                        for (final c in perStudentCtrls.values) {
                          c.text = v == 0 ? '' : v.toString();
                        }
                      },
                      child: const Text('Uygula'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _studentsOfClass.length,
                    itemBuilder: (ctx2, i) {
                      final s = _studentsOfClass[i];
                      final c = perStudentCtrls[s.id]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(s.name)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: c,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  hintText: pointType.affectsFinal ? '1-10' : '0-100',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final validationError = _validateBulkFields(pointType, perStudentCtrls);
                    if (validationError != null) {
                      rootMessenger.showSnackBar(SnackBar(content: Text(validationError)));
                      return;
                    }
                    final dateStr = _dateToStr(widget.selectedDate);
                    for (final s in _studentsOfClass) {
                      final raw = perStudentCtrls[s.id]!.text;
                      final v = parseValue(raw);
                      await widget.repo.upsertDailyEntry(
                        classId: _classId,
                        dateStr: dateStr,
                        studentId: s.id,
                        newValues: {pointType.id: v},
                      );
                    }
                    await widget.onSaved();
                    _resetForSelection();
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    rootMessenger.showSnackBar(
                      const SnackBar(content: Text('Kaydedildi')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      topCtrl.dispose();
      for (final c in perStudentCtrls.values) {
        c.dispose();
      }
    });
  }

  void _resetForSelection() {
    for (final byStudent in _controllers.values) {
      for (final c in byStudent.values) {
        c.dispose();
      }
    }
    _controllers.clear();
    _draftValues.clear();

    _classId = widget.selectedClassId ?? widget.classes.firstOrNull?.id ?? '';
    _studentsOfClass = widget.students.where((s) => s.classId == _classId).toList();
    _applyDateRange();
    _loadControllersFromRepo();
    setState(() {});
  }

  @override
  void dispose() {
    for (final byStudent in _controllers.values) {
      for (final c in byStudent.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  String _dateToStr(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickDate() async {
    final start = _activeRangeStart ?? DateTime(widget.schoolYearStart, 9, 1);
    final end = _activeRangeEnd ?? DateTime(widget.schoolYearStart + 1, 5, 31);

    final initial = widget.selectedDate.isBefore(start) || widget.selectedDate.isAfter(end)
        ? start
        : widget.selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: start,
      lastDate: end,
    );
    if (picked == null) return;
    widget.onSelectDate(picked);
    _resetForSelection();
  }

  List<int> _yearCandidates() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final y = now.year - 2 + i;
      return NotDefterimCalculator.schoolYearStartYearForDate(DateTime(y, 9, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classes.isEmpty) return const Center(child: Text('Önce sınıf ekleyin.'));
    if (widget.pointTypes.isEmpty) return const Center(child: Text('Önce puan türlerini ayarlayin.'));

    if (_classId.isEmpty) return const Center(child: Text('Sınıf secin.'));
    if (_studentsOfClass.isEmpty) {
      return const Center(child: Text('Bu sınıfta öğrenci yok.'));
    }

    final dateStr = _dateToStr(widget.selectedDate);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _classId,
                  decoration: const InputDecoration(labelText: 'Sınıf'),
                  items: widget.classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    widget.onSelectClass(v);
                    setState(() => _classId = v);
                    widget.onSelectDate(widget.selectedDate);
                    // Parent `selectedClassId` bir frame sonra güncellenir; `_resetForSelection`
                    // eski widget değeriyle `_classId` ezmesin diye kuyrukta çalıştır.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _resetForSelection();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(dateStr),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: widget.schoolYearStart,
            decoration: const InputDecoration(labelText: 'Okul Yılı Başlangıç (Eylul yılı)'),
            items: _yearCandidates().map((y) => DropdownMenuItem(value: y, child: Text('$y - ${y + 1}'))).toList(),
            onChanged: (v) {
              if (v == null) return;
              widget.onSelectSchoolYearStart(v);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Ogrenci')),
                  ...widget.pointTypes.map(
                    (pt) => DataColumn(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pt.affectsFinal ? '${pt.name} (1-10)' : pt.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _openBulkEntryPanel(pt),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.add_circle_outline, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                rows: _studentsOfClass.map(
                  (s) {
                    final byTypeControllers = _controllers[s.id] ?? {};
                    return DataRow(
                      cells: [
                        DataCell(Text(s.name)),
                        ...widget.pointTypes.map(
                          (pt) => DataCell(
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: byTypeControllers[pt.id],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(),
                                  hintText: pt.affectsFinal ? '1-10' : '0-100',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final tableErr = _validateTableForSave();
                    if (tableErr != null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tableErr)));
                      return;
                    }
                    final dateStrLocal = _dateToStr(widget.selectedDate);
                    for (final s in _studentsOfClass) {
                      // Kaydetme anında controller'lardan değerleri topla.
                      // Böylece "listener tetiklenmedi" gibi edge-case'ler olmaz.
                      final values = _collectValuesForStudent(s.id);
                      _draftValues[s.id] = values;
                      await widget.repo.upsertDailyEntry(
                        classId: _classId,
                        dateStr: dateStrLocal,
                        studentId: s.id,
                        newValues: values,
                      );
                    }
                    await widget.onSaved();
                    // Hive'dan yeniden okuyup aynı tarih için UI'ı tazele.
                    _resetForSelection();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kaydedildi')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatrixCol {
  final String dateStr;
  final NotDefterimPointType pointType;

  const _MatrixCol({required this.dateStr, required this.pointType});
}

/// Puanlar: Riverpod [notDefterimDailyEntriesProvider] ile aynı Hive kutusundan okur; kayıt sonrası otomatik yenilenir.
class _PointsMatrixTab extends ConsumerStatefulWidget {
  final List<NotDefterimClass> classes;
  final List<NotDefterimStudent> students;
  final List<NotDefterimPointType> pointTypes;
  final String? selectedClassId;
  final int schoolYearStart;

  const _PointsMatrixTab({
    required this.classes,
    required this.students,
    required this.pointTypes,
    required this.selectedClassId,
    required this.schoolYearStart,
  });

  @override
  ConsumerState<_PointsMatrixTab> createState() => _PointsMatrixTabState();
}

class _PointsMatrixTabState extends ConsumerState<_PointsMatrixTab> {
  String? _classId;
  DateTimeRange? _range;
  /// Boş = tüm puan türleri; aksi halde yalnızca seçilen id’ler.
  final Set<String> _pointTypeIdsFilter = {};
  String? _studentId;

  DateTimeRange _defaultYearRange() {
    final y = widget.schoolYearStart;
    return DateTimeRange(
      start: DateTime(y, 9, 1),
      end: DateTime(y + 1, 5, 31),
    );
  }

  @override
  void initState() {
    super.initState();
    _classId = widget.selectedClassId ?? widget.classes.firstOrNull?.id;
    _range = _defaultYearRange();
  }

  @override
  void didUpdateWidget(covariant _PointsMatrixTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolYearStart != widget.schoolYearStart) {
      _range = _defaultYearRange();
    }
    if (oldWidget.selectedClassId != widget.selectedClassId &&
        widget.selectedClassId != null) {
      // didUpdateWidget içinde gereksiz setState, dropdown overlay ile
      // çakışıp "RenderBox was not laid out" zinciri üretebiliyor.
      _classId = widget.selectedClassId;
    }
    final validIds = widget.pointTypes.map((e) => e.id).toSet();
    _pointTypeIdsFilter.removeWhere((id) => !validIds.contains(id));
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final p = dateStr.split('-');
      if (p.length != 3) return null;
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial = _range ?? _defaultYearRange();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 6, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: initial,
    );
    if (picked == null) return;
    setState(() => _range = picked);
  }

  Map<String, double> _cellMapForClass({
    required String classId,
    required List<NotDefterimDailyEntry> entries,
  }) {
    final out = <String, double>{};
    for (final e in entries) {
      if (e.classId != classId) continue;
      for (final kv in e.values.entries) {
        final k = '${e.studentId}|${e.dateStr}|${kv.key}';
        out[k] = kv.value;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(notDefterimDailyEntriesProvider);

    if (widget.classes.isEmpty) return const Center(child: Text('Önce sınıf ekleyin.'));
    if (widget.students.isEmpty) return const Center(child: Text('Önce öğrenci ekleyin.'));
    if (widget.pointTypes.isEmpty) return const Center(child: Text('Önce puan türlerini ayarlayin.'));

    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Hive verisi okundu; henüz günlük puan kaydı yok.\nPuan Ekle sekmesinden kayıt yapın.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final range = _range ?? _defaultYearRange();
    final rangeStart = DateTime(range.start.year, range.start.month, range.start.day);
    final rangeEnd = DateTime(range.end.year, range.end.month, range.end.day);

    final classId = _classId ?? widget.selectedClassId ?? widget.classes.first.id;
    final typesActive = _pointTypeIdsFilter.isEmpty
        ? widget.pointTypes
        : widget.pointTypes.where((p) => _pointTypeIdsFilter.contains(p.id)).toList();

    final datesInData = <String>{};
    for (final e in entries) {
      if (e.classId != classId) continue;
      final d = _parseDate(e.dateStr);
      if (d == null) continue;
      final dd = DateTime(d.year, d.month, d.day);
      if (dd.isBefore(rangeStart) || dd.isAfter(rangeEnd)) continue;
      if (e.values.isEmpty) continue;
      datesInData.add(e.dateStr);
    }
    final sortedDates = datesInData.toList()..sort();

    final cols = <_MatrixCol>[];
    for (final d in sortedDates) {
      for (final pt in typesActive) {
        cols.add(_MatrixCol(dateStr: d, pointType: pt));
      }
    }

    final studentsRows = widget.students.where((s) => s.classId == classId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final studentsFiltered = _studentId == null
        ? studentsRows
        : studentsRows.where((s) => s.id == _studentId).toList();

    final cells = _cellMapForClass(classId: classId, entries: entries);

    String cell(String sid, _MatrixCol c) {
      final k = '$sid|${c.dateStr}|${c.pointType.id}';
      final v = cells[k];
      if (v == null) return '–';
      if (v == 0) return '–';
      return c.pointType.affectsFinal ? v.toStringAsFixed(1) : v.round().toString();
    }

    final isEmptyMatrix = cols.isEmpty || studentsFiltered.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: classId,
                  decoration: const InputDecoration(labelText: 'Sınıf'),
                  items: widget.classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _classId = v;
                      _studentId = null;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  value: _studentId,
                  decoration: const InputDecoration(labelText: 'Öğrenci'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    ...studentsRows.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _studentId = v),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${range.start.year}-${range.start.month.toString().padLeft(2, '0')}-${range.start.day.toString().padLeft(2, '0')}'
                  ' → '
                  '${range.end.year}-${range.end.month.toString().padLeft(2, '0')}-${range.end.day.toString().padLeft(2, '0')}',
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _range = _defaultYearRange();
                  _pointTypeIdsFilter.clear();
                  _studentId = null;
                  _classId = widget.selectedClassId ?? widget.classes.firstOrNull?.id;
                }),
                child: const Text('Sıfırla'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Puan türü (çoklu seçim — hiçbiri işaretli değilken tümü)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Tümü'),
                selected: _pointTypeIdsFilter.isEmpty,
                showCheckmark: false,
                onSelected: (_) => setState(() => _pointTypeIdsFilter.clear()),
              ),
              ...widget.pointTypes.map((p) {
                final allConcept = _pointTypeIdsFilter.isEmpty;
                final selected = allConcept || _pointTypeIdsFilter.contains(p.id);
                return FilterChip(
                  label: Text(p.name),
                  selected: selected,
                  showCheckmark: true,
                  onSelected: (sel) {
                    setState(() {
                      if (allConcept) {
                        if (!sel) {
                          _pointTypeIdsFilter
                            ..clear()
                            ..addAll(
                              widget.pointTypes.where((e) => e.id != p.id).map((e) => e.id),
                            );
                        }
                      } else {
                        if (sel) {
                          _pointTypeIdsFilter.add(p.id);
                        } else {
                          _pointTypeIdsFilter.remove(p.id);
                        }
                        if (_pointTypeIdsFilter.length >= widget.pointTypes.length) {
                          _pointTypeIdsFilter.clear();
                        }
                      }
                    });
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kayıtlı günlük satırı: ${entries.length} • Tablo hücre sayısı: ${cols.length * studentsFiltered.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isEmptyMatrix
                ? Center(
                    child: Text(
                      sortedDates.isEmpty
                          ? 'Bu sınıf ve tarih aralığında veri yok.\nTarihi genişletin veya Puan Ekle ile kayıt yapın.'
                          : 'Bu filtrede tablo oluşturulamıyor (öğrenci veya puan türü seçimi).',
                      textAlign: TextAlign.center,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final mw = constraints.maxWidth;
                      final mh = constraints.maxHeight;
                      if (mw <= 0 || mh <= 0) {
                        return const SizedBox.shrink();
                      }
                      // İç içe ScrollView + DataTable: sınırsız eksende 0 boyut / hit-test
                      // hatasını önlemek için görünür alan kadar minimum kutu ver.
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        primary: false,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          primary: false,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: mw,
                              minHeight: mh,
                            ),
                            child: DataTable(
                              headingRowHeight: 56,
                              dataRowMinHeight: 40,
                              dataRowMaxHeight: 48,
                              columns: [
                                const DataColumn(label: Text('Öğrenci')),
                                ...cols.map(
                                  (c) => DataColumn(
                                    label: Text(
                                      '${c.dateStr}\n${c.pointType.name}',
                                      style: const TextStyle(fontSize: 11),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                              rows: studentsFiltered.map((s) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(s.name)),
                                    ...cols.map(
                                      (c) => DataCell(
                                        Text(
                                          cell(s.id, c),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodReportsTab extends StatefulWidget {
  final NotDefterimRepository repo;
  final List<NotDefterimClass> classes;
  final List<NotDefterimStudent> students;
  final List<NotDefterimPointType> pointTypes;
  final String? selectedClassId;
  final int schoolYearStart;
  final List<NotDefterimDailyEntry> dailyEntries;
  final void Function(String id) onSelectClass;
  final void Function(int yearStart) onSelectSchoolYearStart;

  const _PeriodReportsTab({
    required this.repo,
    required this.classes,
    required this.students,
    required this.pointTypes,
    required this.selectedClassId,
    required this.schoolYearStart,
    required this.dailyEntries,
    required this.onSelectClass,
    required this.onSelectSchoolYearStart,
  });

  @override
  State<_PeriodReportsTab> createState() => _PeriodReportsTabState();
}

class _PeriodReportsTabState extends State<_PeriodReportsTab> {
  List<int> _schoolYearDropdownValues() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final y = now.year - 2 + i;
      return NotDefterimCalculator.schoolYearStartYearForDate(DateTime(y, 9, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classes.isEmpty) return const Center(child: Text('Önce sınıf ekleyin.'));
    if (widget.pointTypes.isEmpty) return const Center(child: Text('Önce puan türlerini ayarlayin.'));

    final classId = widget.selectedClassId ?? widget.classes.first.id;
    final classItem = widget.classes.firstWhere((c) => c.id == classId);
    final classStudents = widget.students.where((s) => s.classId == classId).toList();
    final dailyEntries = widget.dailyEntries;

    final reportPointTypes = widget.pointTypes
        .where(
          (p) =>
              p.kind != NotDefterimPointKind.homework &&
              p.kind != NotDefterimPointKind.exam,
        )
        .toList();

    String formatPeriodTypeSum(NotDefterimPointType t, NotDefterimPeriodSummary s) {
      final v = s.periodSumByPointTypeId[t.id] ?? 0;
      if (v == 0) return '–';
      return t.affectsFinal ? v.toStringAsFixed(1) : v.round().toString();
    }

    final summaries = NotDefterimCalculator.computePeriodSummariesForClass(
      classes: widget.classes,
      students: widget.students,
      pointTypes: widget.pointTypes,
      dailyEntries: dailyEntries,
      classItem: classItem,
      schoolYearStart: widget.schoolYearStart,
    );

    final periods = NotDefterimCalculator.periodsForSchoolYearStart(widget.schoolYearStart);

    final periodKeys = periods.map((p) => p.key).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: classId,
                  decoration: const InputDecoration(labelText: 'Sınıf'),
                  items: widget.classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    widget.onSelectClass(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int>(
                  value: () {
                    final opts = _schoolYearDropdownValues();
                    return opts.contains(widget.schoolYearStart) ? widget.schoolYearStart : opts.first;
                  }(),
                  decoration: const InputDecoration(labelText: 'Okul yılı'),
                  items: [
                    for (final y in _schoolYearDropdownValues())
                      DropdownMenuItem(
                        value: y,
                        child: Text('$y - ${y + 1}'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    widget.onSelectSchoolYearStart(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: periodKeys.length,
              itemBuilder: (ctx, i) {
                final periodKey = periodKeys[i];
                final periodLabel = periods.firstWhere((p) => p.key == periodKey).label;
                final rows = summaries.where((s) => s.periodKey == periodKey).toList()
                  ..sort((a, b) => a.student.name.compareTo(b.student.name));

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(periodLabel, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              const DataColumn(label: Text('Öğrenci')),
                              ...reportPointTypes.map(
                                (p) => DataColumn(
                                  label: Text(
                                    p.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const DataColumn(label: Text('Ödev')),
                              const DataColumn(label: Text('Sınav')),
                              const DataColumn(label: Text('Final (1-10)')),
                            ],
                            rows: rows.map((s) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(s.student.name)),
                                  ...reportPointTypes.map(
                                    (p) => DataCell(Text(formatPeriodTypeSum(p, s))),
                                  ),
                                  DataCell(Text(s.homeworkAverage.toStringAsFixed(2))),
                                  DataCell(Text(s.examAverage.toStringAsFixed(2))),
                                  DataCell(Text('${s.finalGrade1to10}')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (classStudents.isEmpty)
            const Text('Bu sınıfta öğrenci yok.')
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _ExportsTab extends StatefulWidget {
  final NotDefterimRepository repo;
  final List<NotDefterimClass> classes;
  final List<NotDefterimStudent> students;
  final List<NotDefterimPointType> pointTypes;
  final String? selectedClassId;
  final int schoolYearStart;
  final Future<void> Function() onSaved;

  final void Function(String id)? onSelectClass;

  final void Function(int yearStart)? onSelectSchoolYearStart;

  const _ExportsTab({
    required this.repo,
    required this.classes,
    required this.students,
    required this.pointTypes,
    required this.selectedClassId,
    required this.schoolYearStart,
    required this.onSaved,
    this.onSelectClass,
    this.onSelectSchoolYearStart,
  });

  @override
  State<_ExportsTab> createState() => _ExportsTabState();
}

class _ExportsTabState extends State<_ExportsTab> {
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.selectedClassId == null ? null : _studentsForClass().firstOrNull?.id;
  }

  List<NotDefterimStudent> _studentsForClass() {
    final classId = widget.selectedClassId;
    if (classId == null) return const [];
    return widget.students.where((s) => s.classId == classId).toList();
  }

  @override
  void didUpdateWidget(covariant _ExportsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedClassId != widget.selectedClassId) {
      _selectedStudentId = _studentsForClass().firstOrNull?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classes.isEmpty) return const Center(child: Text('Önce sınıf ekleyin.'));
    if (widget.pointTypes.isEmpty) return const Center(child: Text('Önce puan türlerini ayarlayin.'));

    final classId = widget.selectedClassId ?? widget.classes.first.id;
    final classItem = widget.classes.firstWhere((c) => c.id == classId);
    final students = _studentsForClass();

    if (students.isEmpty) {
      return Center(
        child: Text('Seçili sınıfta öğrenci yok: ${classItem.name}'),
      );
    }

    final selectedStudent = students.firstWhere(
      (s) => s.id == (_selectedStudentId ?? ''),
      orElse: () => students.first,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: classId,
                  decoration: const InputDecoration(labelText: 'Sınıf'),
                  items: widget.classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    widget.onSelectClass?.call(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text('Okul yılı: ${widget.schoolYearStart}-${widget.schoolYearStart + 1}', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedStudent.id,
            decoration: const InputDecoration(labelText: 'Öğrenci'),
            items: students
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedStudentId = v);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final classItemLocal = classItem;
              final studentLocal = selectedStudent;
              final dailyEntries = widget.repo.getDailyEntries();
              final path = await NotDefterimExportService.exportStudentPdf(
                student: studentLocal,
                classItem: classItemLocal,
                schoolYearStart: widget.schoolYearStart,
                classes: widget.classes,
                students: widget.students,
                pointTypes: widget.pointTypes,
                dailyEntries: dailyEntries,
              );

              if (path == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF üretilemedi.')));
                return;
              }

              await Share.shareXFiles(
                [XFile(path)],
                text: '${classItemLocal.name} - ${studentLocal.name} Not Raporu',
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Öğrenci PDF Raporu Olustur'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () async {
              final dailyEntries = widget.repo.getDailyEntries();
              final path = await NotDefterimExportService.exportClassExcel(
                classItem: classItem,
                schoolYearStart: widget.schoolYearStart,
                classes: widget.classes,
                students: widget.students,
                pointTypes: widget.pointTypes,
                dailyEntries: dailyEntries,
              );

              if (path == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel üretilemedi.')));
                return;
              }

              await Share.shareXFiles(
                [XFile(path)],
                text: '${classItem.name} - Not Defteri Excel',
              );
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Sınıf Excel Ozet Olustur'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Not: Bu modül tamamen çevrimdışıdır (Hive + yerel dosya üretimi).',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNullExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

