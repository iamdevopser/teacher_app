import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_translations.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/utils/app_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../courses/courses_screen.dart';
import '../teach/teach_screen.dart';
import '../lesson_planner/lesson_planner_screen.dart';
import '../not_defterim/not_defterim_screen.dart';
import '../guidance/guidance_behavior_screen.dart';
import '../reports/reports_screen.dart';
import '../zumre/zumre_screen.dart';

/// Ana kabuk - tek tıkla açılıp kapanan sidebar menü; alt menüler dropdown gibi açılır/kapanır.
/// Sidebar tüm sayfalarda sabit kalır.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  int _initialLessonTab = 0;
  int _initialGuidanceTab = 0;
  int _initialZumreTab = 0;
  int _initialNotDefterimTab = 0;
  bool _sidebarOpen = false;
  bool _kurslarimExpanded = false;
  bool _plansExpanded = false;
  bool _notDefterimExpanded = false;
  bool _guidanceExpanded = false;
  bool _zumreExpanded = false;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    8,
    (_) => GlobalKey<NavigatorState>(),
  );

  List<Widget> _buildScreens() => [
    const DashboardScreen(),
    const CoursesScreen(),
    const TeachScreen(),
    LessonPlannerScreen(initialTabIndex: _initialLessonTab),
    NotDefterimScreen(
      key: const ValueKey<String>('shell_not_defterim'),
      initialTabIndex: _initialNotDefterimTab,
      onSyncedTabIndex: _onNotDefterimTabFromBar,
    ),
    GuidanceBehaviorScreen(initialTabIndex: _initialGuidanceTab),
    ZumreScreen(initialTabIndex: _initialZumreTab),
    const ReportsScreen(),
  ];

  String _screenPageKey(int index) {
    switch (index) {
      case 3:
        return 'lesson_$_initialLessonTab';
      case 5:
        return 'guidance_$_initialGuidanceTab';
      case 6:
        return 'zumre_$_initialZumreTab';
      default:
        return 'screen_$index';
    }
  }

  /// TabBar’dan gelen indeks; [ValueKey] + sabit tear-off ile her build’de yeni closure yok.
  void _onNotDefterimTabFromBar(int tab) {
    _switchTo(4, notDefterimTab: tab, closeSidebar: false);
  }

  void _switchTo(
    int index, {
    int? lessonTab,
    int? guidanceTab,
    int? zumreTab,
    int? notDefterimTab,
    bool closeSidebar = true,
  }) {
    final nextNd = notDefterimTab != null
        ? notDefterimTab.clamp(0, 6)
        : _initialNotDefterimTab;

    final routeUnchanged = _selectedIndex == index &&
        (lessonTab == null || lessonTab == _initialLessonTab) &&
        (guidanceTab == null || guidanceTab == _initialGuidanceTab) &&
        (zumreTab == null || zumreTab == _initialZumreTab) &&
        (notDefterimTab == null || nextNd == _initialNotDefterimTab);

    final sidebarUnchanged = !closeSidebar || !_sidebarOpen;

    if (routeUnchanged && sidebarUnchanged) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      if (lessonTab != null) _initialLessonTab = lessonTab;
      if (guidanceTab != null) _initialGuidanceTab = guidanceTab;
      if (zumreTab != null) _initialZumreTab = zumreTab;
      if (notDefterimTab != null) {
        _initialNotDefterimTab = nextNd;
      }
      if (index == 1 || index == 2) _kurslarimExpanded = true;
      if (index == 3) _plansExpanded = true;
      if (index == 4) _notDefterimExpanded = true;
      if (index == 5) _guidanceExpanded = true;
      if (index == 6) _zumreExpanded = true;
      _sidebarOpen = closeSidebar ? false : _sidebarOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    _kurslarimExpanded = _selectedIndex == 1 || _selectedIndex == 2;
    _plansExpanded = _selectedIndex == 3;
    _notDefterimExpanded = _selectedIndex == 4;
    _guidanceExpanded = _selectedIndex == 5;
    _zumreExpanded = _selectedIndex == 6;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    context.watch<AppProvider>();
    final localeCode = context
        .watch<LocaleProvider>()
        .effectiveLocale
        .languageCode;
    final screens = _buildScreens();
    final screenSize = MediaQuery.sizeOf(context);
    final isNarrow = screenSize.shortestSide < 600;
    final compactSidebarWidth = (screenSize.width * 0.82).clamp(220.0, 280.0);

    return MainShellScope(
      selectedIndex: _selectedIndex,
      initialLessonTab: _initialLessonTab,
      initialGuidanceTab: _initialGuidanceTab,
      initialZumreTab: _initialZumreTab,
      initialNotDefterimTab: _initialNotDefterimTab,
      onSwitchTo: _switchTo,
      child: Scaffold(
        body: isNarrow
            ? Stack(
                children: [
                  _buildContent(context, screens),
                  if (_sidebarOpen) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => setState(() => _sidebarOpen = false),
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      child: _buildSidebar(
                        context,
                        localeCode,
                        widthOverride: compactSidebarWidth,
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  _buildSidebar(context, localeCode),
                  Expanded(child: _buildContent(context, screens)),
                ],
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Widget> screens) {
    return Stack(
      children: [
        IndexedStack(
          index: _selectedIndex,
          children: List.generate(8, (i) {
            final page = screens[i];
            // Not Defterim: iç Navigator kaldırıldı (çift route + hızlı tıklamada jank).
            if (i == 4) {
              return KeyedSubtree(
                key: const ValueKey<String>('indexed_not_defterim'),
                child: page,
              );
            }
            return Navigator(
              key: _navigatorKeys[i],
              pages: [
                MaterialPage<void>(
                  key: ValueKey(_screenPageKey(i)),
                  child: page,
                ),
              ],
              onPopPage: (route, result) => route.didPop(result),
            );
          }),
        ),
        if (!_sidebarOpen)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: context.tr('home'),
                onPressed: () => setState(() => _sidebarOpen = true),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    String localeCode, {
    double? widthOverride,
  }) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final isNarrow = screenSize.shortestSide < 600;
    final compactSidebarWidth = (screenSize.width * 0.82).clamp(220.0, 280.0);
    final width =
        widthOverride ??
        (_sidebarOpen ? (isNarrow ? compactSidebarWidth : 260.0) : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: _sidebarOpen ? theme.dividerColor : Colors.transparent,
          ),
        ),
      ),
      child: _sidebarOpen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 12,
                    12,
                    8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppTranslations.tr(localeCode, 'appTitle'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(isNarrow ? Icons.close : Icons.chevron_left),
                        onPressed: () => setState(() => _sidebarOpen = false),
                        tooltip: context.tr('close'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _navTile(context, localeCode, 0, Icons.dashboard, 'home'),
                      _expandableSection(
                        context,
                        localeCode,
                        titleKey: 'myCourses',
                        icon: Icons.menu_book,
                        selected: _selectedIndex == 1 || _selectedIndex == 2,
                        expanded: _kurslarimExpanded,
                        onExpand: () => setState(() {
                          _kurslarimExpanded = !_kurslarimExpanded;
                          if (_kurslarimExpanded) {
                            _selectedIndex = 1;
                          }
                        }),
                        subItems: [
                          (Icons.menu_book, 'courses', 0),
                          (Icons.school, 'myLessons', 1),
                        ],
                        onSubTap: (tab) =>
                            _switchTo(tab == 0 ? 1 : 2, closeSidebar: false),
                        currentSub: _selectedIndex == 1
                            ? 0
                            : (_selectedIndex == 2 ? 1 : 0),
                      ),
                      _expandableSection(
                        context,
                        localeCode,
                        titleKey: 'plans',
                        icon: Icons.calendar_month,
                        selected: _selectedIndex == 3,
                        expanded: _plansExpanded,
                        onExpand: () => setState(() {
                          _plansExpanded = !_plansExpanded;
                          if (_plansExpanded) {
                            _selectedIndex = 3;
                            _initialLessonTab = 0;
                          }
                        }),
                        subItems: [
                          (Icons.calendar_view_week, 'weeklySchedule', 0),
                          (Icons.calendar_month, 'annualPlan', 1),
                          (Icons.today, 'dailyPlan', 2),
                          (Icons.folder, 'documents', 3),
                          (Icons.work_outline, 'projects', 4),
                        ],
                        onSubTap: (tab) =>
                            _switchTo(3, lessonTab: tab, closeSidebar: false),
                        currentSub: _initialLessonTab,
                      ),
                      _expandableSection(
                        context,
                        localeCode,
                        titleKey: 'notDefterim',
                        icon: Icons.note_alt_outlined,
                        selected: _selectedIndex == 4,
                        expanded: _notDefterimExpanded,
                        onExpand: () => setState(() {
                          _notDefterimExpanded = !_notDefterimExpanded;
                          if (_notDefterimExpanded) {
                            _selectedIndex = 4;
                          }
                        }),
                        subItems: [
                          (Icons.tune, 'notDefterimTabSetup', 0),
                          (Icons.class_, 'notDefterimTabClasses', 1),
                          (Icons.people_outline, 'notDefterimTabStudents', 2),
                          (Icons.edit_note, 'notDefterimTabAddPoints', 3),
                          (Icons.table_chart_outlined, 'notDefterimTabPoints', 4),
                          (Icons.assessment_outlined, 'notDefterimTabPeriodReport', 5),
                          (Icons.upload_file_outlined, 'notDefterimTabExport', 6),
                        ],
                        onSubTap: (tab) => _switchTo(
                          4,
                          notDefterimTab: tab,
                          closeSidebar: false,
                        ),
                        currentSub: _initialNotDefterimTab,
                      ),
                      _expandableSection(
                        context,
                        localeCode,
                        titleKey: 'guidance',
                        icon: Icons.psychology,
                        selected: _selectedIndex == 5,
                        expanded: _guidanceExpanded,
                        onExpand: () => setState(() {
                          _guidanceExpanded = !_guidanceExpanded;
                          if (_guidanceExpanded) {
                            _selectedIndex = 5;
                            _initialGuidanceTab = 0;
                          }
                        }),
                        subItems: [
                          (Icons.people, 'guidanceClassTab', 0),
                          (Icons.warning_amber, 'studentProblemsTab', 1),
                          (Icons.note, 'guidanceNotesTab', 2),
                          (Icons.trending_up, 'guidanceDevelopmentTab', 3),
                        ],
                        onSubTap: (tab) =>
                            _switchTo(5, guidanceTab: tab, closeSidebar: false),
                        currentSub: _initialGuidanceTab,
                      ),
                      _expandableSection(
                        context,
                        localeCode,
                        titleKey: 'zumre_title',
                        icon: Icons.groups,
                        selected: _selectedIndex == 6,
                        expanded: _zumreExpanded,
                        onExpand: () => setState(() {
                          _zumreExpanded = !_zumreExpanded;
                          if (_zumreExpanded) {
                            _selectedIndex = 6;
                            _initialZumreTab = 0;
                          }
                        }),
                        subItems: [
                          (Icons.info_outline, 'zumre_tab_definition', 0),
                          (Icons.groups, 'zumre_tab_meetings', 1),
                          (Icons.task_alt, 'zumre_tab_tasks', 2),
                          (
                            Icons.lightbulb_outline,
                            'zumre_tab_contributions',
                            3,
                          ),
                          (Icons.gavel, 'zumre_tab_decisions', 4),
                          (Icons.note, 'zumre_tab_notes', 5),
                          (Icons.summarize, 'zumre_tab_reports', 6),
                        ],
                        onSubTap: (tab) =>
                            _switchTo(6, zumreTab: tab, closeSidebar: false),
                        currentSub: _initialZumreTab,
                      ),
                      _navTile(context, localeCode, 7, Icons.report, 'reports'),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _navTile(
    BuildContext context,
    String localeCode,
    int index,
    IconData icon,
    String labelKey,
  ) {
    final selected = _selectedIndex == index;
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).shortestSide < 600;
    return ListTile(
      dense: isCompact,
      leading: Icon(
        icon,
        size: isCompact ? 20 : 22,
        color: selected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        AppTranslations.tr(localeCode, labelKey),
        style: TextStyle(
          fontSize: isCompact ? 13 : null,
          fontWeight: selected ? FontWeight.w600 : null,
          color: selected ? theme.colorScheme.primary : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      onTap: () => _switchTo(index),
    );
  }

  Widget _expandableSection(
    BuildContext context,
    String localeCode, {
    required String titleKey,
    required IconData icon,
    required bool selected,
    required bool expanded,
    required VoidCallback onExpand,
    required List<(IconData, String, int)> subItems,
    required void Function(int) onSubTap,
    required int currentSub,
  }) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).shortestSide < 600;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: isCompact,
          leading: Icon(
            icon,
            size: isCompact ? 20 : 22,
            color: selected ? theme.colorScheme.primary : null,
          ),
          title: Text(
            AppTranslations.tr(localeCode, titleKey),
            style: TextStyle(
              fontSize: isCompact ? 13 : null,
              fontWeight: selected ? FontWeight.w600 : null,
              color: selected ? theme.colorScheme.primary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 22,
          ),
          selected: selected,
          onTap: onExpand,
        ),
        if (expanded)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: subItems.map((e) {
              final (subIcon, subKey, subIndex) = e;
              final isCurrent = selected && currentSub == subIndex;
              return ListTile(
                dense: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    subIcon,
                    size: isCompact ? 16 : 18,
                    color: isCurrent ? theme.colorScheme.primary : null,
                  ),
                ),
                title: Text(
                  AppTranslations.tr(localeCode, subKey),
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: isCurrent ? theme.colorScheme.primary : null,
                    fontWeight: isCurrent ? FontWeight.w600 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: isCurrent,
                onTap: () => onSubTap(subIndex),
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// Tüm sayfalarda erişilebilir; sekme ve alt sekme geçişi için.
class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.selectedIndex,
    required this.onSwitchTo,
    required super.child,
    this.initialLessonTab = 0,
    this.initialGuidanceTab = 0,
    this.initialZumreTab = 0,
    this.initialNotDefterimTab = 0,
  });

  final int selectedIndex;
  final int initialLessonTab;
  final int initialGuidanceTab;
  final int initialZumreTab;
  final int initialNotDefterimTab;
  final void Function(
    int index, {
    int? lessonTab,
    int? guidanceTab,
    int? zumreTab,
    int? notDefterimTab,
    bool closeSidebar,
  })
  onSwitchTo;

  static MainShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  /// Örnek: onSwitchTo(4) -> Not Defterim (son alt sekme korunur).
  void switchTo(int index) => onSwitchTo(index);

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      selectedIndex != oldWidget.selectedIndex ||
      initialLessonTab != oldWidget.initialLessonTab ||
      initialGuidanceTab != oldWidget.initialGuidanceTab ||
      initialZumreTab != oldWidget.initialZumreTab ||
      initialNotDefterimTab != oldWidget.initialNotDefterimTab;
}
