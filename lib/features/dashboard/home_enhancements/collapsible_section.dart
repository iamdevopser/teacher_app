import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/utils/app_provider.dart';
/// ADDITIVE: Wraps content in a collapsible section.
/// When disabled, just shows the child without collapse behavior.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.sectionId,
    required this.title,
    required this.child,
  });

  final String sectionId;
  final String title;
  final Widget child;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadState());
  }

  void _loadState() {
    if (!mounted) return;
    final collapsed = context.read<AppProvider>().repo.getHomeSectionsCollapsed();
    if (mounted) {
      setState(() => _collapsed = collapsed.contains(widget.sectionId));
    }
  }

  Future<void> _toggle() async {
    if (!FeatureFlags.homeCollapsibleSections) return;
    setState(() => _collapsed = !_collapsed);
    await context.read<AppProvider>().repo.setHomeSectionCollapsed(
          widget.sectionId,
          _collapsed,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.homeCollapsibleSections) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          widget.child,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _collapsed ? Icons.expand_more : Icons.expand_less,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_collapsed) widget.child,
      ],
    );
  }
}
