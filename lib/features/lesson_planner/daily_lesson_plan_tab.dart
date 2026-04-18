import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/lesson_planner_models.dart';
import '../../data/services/daily_plan_file_service.dart';
import 'daily_lesson_plan_form.dart';
import 'planner_split_view.dart';

class DailyLessonPlanTab extends StatefulWidget {
  const DailyLessonPlanTab({super.key});

  @override
  State<DailyLessonPlanTab> createState() => _DailyLessonPlanTabState();
}

class _DailyLessonPlanTabState extends State<DailyLessonPlanTab> {
  DateTime _selectedDate = DateTime.now();
  List<DailyLessonPlan> _plans = [];
  bool _showAllPlans = false;
  String _dailyReflection = '';
  final TextEditingController _reflectionController = TextEditingController();
  DailyLessonPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  void _load() {
    final repo = context.read<AppProvider>().repo;
    if (_showAllPlans) {
      _plans = repo.getDailyLessonPlans()
        ..sort((a, b) => b.date.compareTo(a.date));
    } else {
      _plans = repo.getDailyLessonPlansByDate(_selectedDate);
    }
    if (FeatureFlags.dailyReflectionNote && !_showAllPlans) {
      _dailyReflection = repo.getDailyReflection(_selectedDate);
      _reflectionController.text = _dailyReflection;
    }
    if (_selectedPlan != null) {
      final selectedId = _selectedPlan!.id;
      try {
        _selectedPlan = _plans.firstWhere((plan) => plan.id == selectedId);
      } catch (_) {
        _selectedPlan = _plans.isNotEmpty ? _plans.first : null;
      }
    } else if (_plans.length == 1) {
      _selectedPlan = _plans.first;
    }
    setState(() {});
  }

  Future<void> _saveReflection() async {
    if (!FeatureFlags.dailyReflectionNote) return;
    await context.read<AppProvider>().repo.setDailyReflection(
      _selectedDate,
      _reflectionController.text,
    );
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('saved'))));
  }

  Future<void> _addPlan() async {
    final profile = context.read<AppProvider>().profile;
    var plan = await showDialog<DailyLessonPlan>(
      context: context,
      builder: (_) => DailyLessonPlanForm(
        initialDate: _selectedDate,
        teacherName: profile?.teacherName ?? '',
      ),
    );
    if (plan != null && mounted) {
      final filePath = await DailyPlanFileService.generatePlanFile(plan);
      if (filePath != null) {
        plan = DailyLessonPlan(
          id: plan.id,
          subjectName: plan.subjectName,
          classId: plan.classId,
          teacherName: plan.teacherName,
          date: plan.date,
          weekNo: plan.weekNo,
          lessonNo: plan.lessonNo,
          lessonHour: plan.lessonHour,
          topic: plan.topic,
          outcome: plan.outcome,
          intro: plan.intro,
          development: plan.development,
          evaluation: plan.evaluation,
          method: plan.method,
          material: plan.material,
          lessonNote: plan.lessonNote,
          completed: plan.completed,
          needsMakeup: plan.needsMakeup,
          isPlanned: plan.isPlanned,
          createdAt: plan.createdAt,
          filePath: filePath,
          lessonType: plan.lessonType,
          lessonLink: plan.lessonLink,
          lessonDurationMinutes: plan.lessonDurationMinutes,
          linkedGroupId: plan.linkedGroupId,
        );
      }
      await context.read<AppProvider>().repo.addDailyLessonPlan(plan);
      _load();
    }
  }

  Future<void> _editPlan(DailyLessonPlan p) async {
    var updated = await showDialog<DailyLessonPlan>(
      context: context,
      builder: (_) => DailyLessonPlanForm(plan: p),
    );
    if (updated != null && mounted) {
      var planToSave = updated!;
      final filePath = await DailyPlanFileService.generatePlanFile(planToSave);
      if (filePath != null) {
        planToSave = DailyLessonPlan(
          id: planToSave.id,
          subjectName: planToSave.subjectName,
          classId: planToSave.classId,
          teacherName: planToSave.teacherName,
          date: planToSave.date,
          weekNo: planToSave.weekNo,
          lessonNo: planToSave.lessonNo,
          lessonHour: planToSave.lessonHour,
          topic: planToSave.topic,
          outcome: planToSave.outcome,
          intro: planToSave.intro,
          development: planToSave.development,
          evaluation: planToSave.evaluation,
          method: planToSave.method,
          material: planToSave.material,
          lessonNote: planToSave.lessonNote,
          completed: planToSave.completed,
          needsMakeup: planToSave.needsMakeup,
          isPlanned: planToSave.isPlanned,
          createdAt: planToSave.createdAt,
          filePath: filePath,
          lessonType: planToSave.lessonType,
          lessonLink: planToSave.lessonLink,
          lessonDurationMinutes: planToSave.lessonDurationMinutes,
          linkedGroupId: planToSave.linkedGroupId,
        );
      }
      await context.read<AppProvider>().repo.updateDailyLessonPlan(planToSave);
      // Tarih değiştiyse seçili tarihi güncelle ki plan görünsün
      final dateChanged =
          p.date.year != planToSave.date.year ||
          p.date.month != planToSave.date.month ||
          p.date.day != planToSave.date.day;
      if (dateChanged) {
        setState(() => _selectedDate = planToSave.date);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${context.tr('planMovedToDate')}: ${planToSave.date.day}/${planToSave.date.month}/${planToSave.date.year}',
              ),
            ),
          );
        }
      }
      _load();
      setState(() => _selectedPlan = planToSave);
    }
  }

  Future<void> _sharePlan(DailyLessonPlan p) async {
    String? path = p.filePath;
    if (path == null || !File(path).existsSync()) {
      path = await DailyPlanFileService.generatePlanFile(p);
    }
    if (path != null) {
      await Share.shareXFiles([
        XFile(path),
      ], text: '${p.subjectName} - ${p.classId}');
    }
  }

  void _copyPlanLink(DailyLessonPlan p) {
    final content = DailyPlanFileService.getPlanContentAsText(p);
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('copiedToClipboard'))));
  }

  void _showPlanFileDialog(DailyLessonPlan p) {
    final content = DailyPlanFileService.getPlanContentAsText(p);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${p.subjectName} - ${p.classId}'),
        content: SizedBox(
          width: 500,
          height: 500,
          child: SelectableText(
            content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }

  void _showMobilePlanDetails(DailyLessonPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${plan.subjectName} - ${plan.classId}',
                        style: Theme.of(ctx).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildPlanDetailsPanel(
                  plan,
                  isWide: false,
                  showHeader: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlan(DailyLessonPlan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deletePlan')),
        content: Text(context.tr('deletePlanConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().repo.deleteDailyLessonPlan(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    final isCompact = MediaQuery.sizeOf(context).shortestSide < 600;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(right: isCompact ? 0 : 8),
                child: Text(context.tr('dailyPlan')),
              ),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) {
                    setState(() {
                      _selectedDate = d;
                      _load();
                    });
                  }
                },
                child: Chip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
              FilterChip(
                label: Text(context.tr('showAllPlans')),
                selected: _showAllPlans,
                onSelected: (v) {
                  setState(() {
                    _showAllPlans = v;
                    _selectedPlan = null;
                    _load();
                  });
                },
              ),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: _addPlan,
                tooltip: context.tr('addPlan'),
              ),
            ],
          ),
        ),
        if (FeatureFlags.dailyReflectionNote && !_showAllPlans)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('dailyReflectionNote'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reflectionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: context.tr('dailyReflectionHint'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => _dailyReflection = v,
                      onSubmitted: (_) => _saveReflection(),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _saveReflection,
                        icon: const Icon(Icons.save, size: 18),
                        label: Text(context.tr('save')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: PlannerSplitView(
            emptyState: _plans.isNotEmpty ? _buildPlanPanelPlaceholder() : null,
            onClosePanel: _selectedPlan != null
                ? () => setState(() => _selectedPlan = null)
                : null,
            sidePanel: _selectedPlan != null
                ? _buildPlanDetailsPanel(_selectedPlan!, isWide: isWide)
                : null,
            content: _plans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showAllPlans
                              ? context.tr('noPlansYet')
                              : context.tr('noPlanForDate'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _addPlan,
                          child: Text(context.tr('addPlan')),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _plans.length,
                    itemBuilder: (_, i) {
                      final p = _plans[i];
                      final isSelected = _selectedPlan?.id == p.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.35)
                            : null,
                        child: ListTile(
                          leading: Icon(
                            p.completed
                                ? Icons.check_circle
                                : (p.needsMakeup
                                      ? Icons.warning_amber
                                      : Icons.assignment),
                            color: p.completed
                                ? Colors.green
                                : (p.needsMakeup ? Colors.orange : null),
                          ),
                          title: Text('${p.subjectName} - ${p.classId}'),
                          subtitle: Text(
                            _showAllPlans
                                ? '${p.date.day}/${p.date.month}/${p.date.year} • ${p.topic}'
                                : p.topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isWide
                              ? const Icon(Icons.chevron_right)
                              : null,
                          onTap: () {
                            if (isWide) {
                              setState(() => _selectedPlan = p);
                            } else {
                              _showMobilePlanDetails(p);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanPanelPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.tr('selectItemToOpenSidebar'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildPlanDetailsPanel(
    DailyLessonPlan plan, {
    required bool isWide,
    bool showHeader = true,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Text(plan.subjectName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${plan.classId} • ${plan.date.day}/${plan.date.month}/${plan.date.year}',
            ),
            const SizedBox(height: 16),
          ],
          _detailRow(context.tr('topic'), plan.topic),
          _detailRow(context.tr('outcome'), plan.outcome),
          _detailRow(context.tr('method'), plan.method),
          _detailRow(context.tr('material'), plan.material),
          _detailRow(context.tr('teacherComment'), plan.lessonNote),
          if ((plan.lessonType ?? '').isNotEmpty)
            _detailRow(
              context.tr('lessonType'),
              _lessonTypeLabel(plan.lessonType),
            ),
          if ((plan.lessonLink ?? '').isNotEmpty)
            _detailRow(context.tr('lessonLink'), plan.lessonLink),
          if (plan.lessonDurationMinutes != null)
            _detailRow(
              context.tr('lessonDurationMinutes'),
              '${plan.lessonDurationMinutes}',
            ),
          if ((plan.linkedGroupId ?? '').isNotEmpty)
            _detailRow(context.tr('linkedGroup'), plan.linkedGroupId),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _copyPlanLink(plan),
                icon: const Icon(Icons.link),
                label: Text(context.tr('copyLink')),
              ),
              FilledButton.icon(
                onPressed: () => _sharePlan(plan),
                icon: const Icon(Icons.share),
                label: Text(context.tr('shareDailyPlan')),
              ),
              FilledButton.icon(
                onPressed: () => _showPlanFileDialog(plan),
                icon: const Icon(Icons.description),
                label: Text(context.tr('viewPlanFile')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _editPlan(plan),
                icon: const Icon(Icons.edit),
                label: Text(context.tr('edit')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _deletePlan(plan),
                icon: const Icon(Icons.delete),
                label: Text(context.tr('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  String _lessonTypeLabel(String? value) {
    switch (value) {
      case 'online':
        return context.tr('lessonTypeOnline');
      case 'hybrid':
        return context.tr('lessonTypeHybrid');
      case 'face_to_face':
      default:
        return context.tr('lessonTypeFaceToFace');
    }
  }
}
