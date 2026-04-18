import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import 'weekly_schedule_tab.dart';
import 'annual_plan_tab.dart';
import 'daily_lesson_plan_tab.dart';
import 'lesson_documents_tab.dart';
import 'projects_tab.dart';

/// Ders Planı ekranı - 5 ana bölüm; sidebar ile alt sekme seçilebilir.
class LessonPlannerScreen extends StatefulWidget {
  const LessonPlannerScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<LessonPlannerScreen> createState() => _LessonPlannerScreenState();
}

class _LessonPlannerScreenState extends State<LessonPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialTabIndex.clamp(0, 4),
      length: 5,
      vsync: this,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(LessonPlannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        widget.initialTabIndex >= 0 &&
        widget.initialTabIndex < 5) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plans')),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.calendar_view_week), text: context.tr('weeklySchedule')),
            Tab(icon: const Icon(Icons.calendar_month), text: context.tr('annualPlan')),
            Tab(icon: const Icon(Icons.today), text: context.tr('dailyPlan')),
            Tab(icon: const Icon(Icons.folder), text: context.tr('documents')),
            Tab(icon: const Icon(Icons.work_outline), text: context.tr('projects')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SizedBox.expand(child: WeeklyScheduleTab()),
          SizedBox.expand(child: AnnualPlanTab()),
          SizedBox.expand(child: DailyLessonPlanTab()),
          SizedBox.expand(child: LessonDocumentsTab()),
          SizedBox.expand(child: ProjectsTab()),
        ],
      ),
    );
  }
}
