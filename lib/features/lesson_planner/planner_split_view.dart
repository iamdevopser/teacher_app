import 'package:flutter/material.dart';

class PlannerSplitView extends StatelessWidget {
  const PlannerSplitView({
    required this.content,
    this.sidePanel,
    this.onClosePanel,
    this.breakpoint = 1100,
    this.panelWidth = 360,
    this.emptyState,
    super.key,
  });

  final Widget content;
  final Widget? sidePanel;
  final VoidCallback? onClosePanel;
  final double breakpoint;
  final double panelWidth;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= breakpoint;
    if (!isWide) return content;

    return Row(
      children: [
        Expanded(child: content),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: sidePanel != null || emptyState != null ? panelWidth : 0,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor),
            ),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
          child: sidePanel != null
              ? Column(
                  children: [
                    if (onClosePanel != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: onClosePanel,
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    Expanded(child: sidePanel!),
                  ],
                )
              : emptyState ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}
