import 'package:flutter/material.dart';
import '../../core/localization/tr_extension.dart';

/// ADDITIVE: Simple color picker for course metadata.
class CourseColorDialog extends StatelessWidget {
  const CourseColorDialog({super.key, this.initialColor, this.title, this.onClear});

  final Color? initialColor;
  final String? title;
  final Future<void> Function()? onClear;

  static const List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? context.tr('courseSetColor')),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _colors.map((c) {
          final selected = initialColor?.value == c.value;
          return GestureDetector(
            onTap: () => Navigator.pop(context, c),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: selected ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: selected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] : null,
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        if (initialColor != null && onClear != null)
          TextButton(
            onPressed: () async {
              await onClear!();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.tr('courseClearColor')),
          ),
      ],
    );
  }
}
