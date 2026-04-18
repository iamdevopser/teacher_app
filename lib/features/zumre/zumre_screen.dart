import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import 'zumre_definition_screen.dart';
import 'zumre_meetings_screen.dart';
import 'zumre_tasks_screen.dart';
import 'zumre_contributions_screen.dart';
import 'zumre_decisions_screen.dart';
import 'zumre_notes_screen.dart';
import 'zumre_reports_screen.dart';

/// Zümre Çalışmalarım ana ekranı - 7 alt modül; sidebar ile alt sekme seçilebilir.
class ZumreScreen extends StatefulWidget {
  const ZumreScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<ZumreScreen> createState() => _ZumreScreenState();
}

class _ZumreScreenState extends State<ZumreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialTabIndex.clamp(0, 6),
      length: 7,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ZumreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        widget.initialTabIndex >= 0 &&
        widget.initialTabIndex < 7) {
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
        title: Text(context.tr('zumre_title')),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.info_outline), text: context.tr('zumre_tab_definition')),
            Tab(icon: const Icon(Icons.groups), text: context.tr('zumre_tab_meetings')),
            Tab(icon: const Icon(Icons.task_alt), text: context.tr('zumre_tab_tasks')),
            Tab(icon: const Icon(Icons.lightbulb_outline), text: context.tr('zumre_tab_contributions')),
            Tab(icon: const Icon(Icons.gavel), text: context.tr('zumre_tab_decisions')),
            Tab(icon: const Icon(Icons.note), text: context.tr('zumre_tab_notes')),
            Tab(icon: const Icon(Icons.summarize), text: context.tr('zumre_tab_reports')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ZumreDefinitionScreen(),
          ZumreMeetingsScreen(),
          ZumreTasksScreen(),
          ZumreContributionsScreen(),
          ZumreDecisionsScreen(),
          ZumreNotesScreen(),
          ZumreReportsScreen(),
        ],
      ),
    );
  }
}
