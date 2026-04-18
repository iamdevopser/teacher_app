import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/tr_extension.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/utils/app_provider.dart';
import '../../../data/models/course.dart';
import '../../main_shell/main_shell_screen.dart';
import '../../courses/course_detail_screen.dart';

/// ADDITIVE: Recent items - last opened course/document.
/// Does not affect existing layout when empty.
class RecentItemsCard extends StatelessWidget {
  const RecentItemsCard({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.homeRecentItems) return const SizedBox.shrink();

    final repo = context.read<AppProvider>().repo;
    final lastCourseId = repo.getLastSelectedCourseId();
    final lastDoc = repo.getLastOpenedDocument();

    if (lastCourseId == null && lastDoc == null) return const SizedBox.shrink();

    final courses = repo.getCourses();
    Course? lastCourse;
    if (lastCourseId != null) {
      try {
        lastCourse = courses.firstWhere((c) => c.id == lastCourseId);
      } catch (_) {
        lastCourse = null;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                context.tr('recentItems'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            if (lastCourse != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.menu_book, size: 24),
                title: Text(
                  lastCourse.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(context.tr('lastOpenedCourse')),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(course: lastCourse!),
                  ),
                ),
              ),
            if (lastDoc != null && lastDoc.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.description, size: 24),
                title: Text(
                  lastDoc.split(RegExp(r'[/\\]')).last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(context.tr('lastOpenedDocument')),
                onTap: () {
                  MainShellScope.of(context)?.onSwitchTo(2);
                  // Document would open in Teach - requires passing path
                  // For now just switch to Teach
                },
              ),
          ],
        ),
      ),
    );
  }
}
