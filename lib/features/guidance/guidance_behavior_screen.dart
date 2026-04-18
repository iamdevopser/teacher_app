import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import 'guidance_class_screen.dart';
import 'guidance_problems_screen.dart';
import 'guidance_notes_screen.dart';
import 'guidance_development_screen.dart';

/// Rehberlik ana ekranı: Sınıfım, Öğrenci Problemleri, Rehberlik Notları; sidebar ile alt sekme seçilebilir.
class GuidanceBehaviorScreen extends StatefulWidget {
  const GuidanceBehaviorScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<GuidanceBehaviorScreen> createState() => _GuidanceBehaviorScreenState();
}

class _GuidanceBehaviorScreenState extends State<GuidanceBehaviorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialTabIndex.clamp(0, 3),
      length: 4,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(GuidanceBehaviorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        widget.initialTabIndex >= 0 &&
        widget.initialTabIndex < 4) {
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
        title: Text(context.tr('guidance')),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.people), text: context.tr('guidanceClassTab')),
            Tab(icon: const Icon(Icons.warning_amber), text: context.tr('studentProblemsTab')),
            Tab(icon: const Icon(Icons.note), text: context.tr('guidanceNotesTab')),
            Tab(icon: const Icon(Icons.trending_up), text: context.tr('guidanceDevelopmentTab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GuidanceClassScreen(),
          GuidanceProblemsScreen(),
          GuidanceNotesScreen(),
          GuidanceDevelopmentScreen(),
        ],
      ),
    );
  }
}
