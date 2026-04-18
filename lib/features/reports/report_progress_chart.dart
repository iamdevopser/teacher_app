import 'package:flutter/material.dart';
import '../../data/models/assessment.dart';

/// ADDITIVE: Simple bar chart for student assessment scores over time.
class ReportProgressChart extends StatelessWidget {
  const ReportProgressChart({super.key, required this.assessments, this.maxBars = 10});

  final List<Assessment> assessments;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final items = assessments.take(maxBars).toList().reversed.toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No assessment data',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final maxScore = items.map((a) => a.score).reduce((a, b) => a > b ? a : b);
    final minScore = items.map((a) => a.score).reduce((a, b) => a < b ? a : b);
    final range = (maxScore - minScore).clamp(1.0, 100.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items.map((a) {
                  final frac = ((a.score - minScore) / range).clamp(0.1, 1.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            a.score.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 80 * frac,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${a.date.day}/${a.date.month}',
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
